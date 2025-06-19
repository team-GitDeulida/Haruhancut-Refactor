//  ProfileViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/19/25.
//

import UIKit
import RxSwift

final class ProfileViewController: UIViewController {
    weak var coordinator: HomeCoordinator?
    private let profileViewModel: ProfileViewModelType
    private let homeViewModel: HomeViewModelType
    private let loginViewModel: LoginViewModelType
    private let customView: ProfileView
    private let disposeBag = DisposeBag()
    
    // MARK: - Initializer
    init(profileViewModel: ProfileViewModelType,
         homeViewModel: HomeViewModelType,
         loginViewModel: LoginViewModelType
    ) {
        self.profileViewModel = profileViewModel
        self.homeViewModel = homeViewModel
        self.loginViewModel = loginViewModel
        self.customView = ProfileView(nickname: homeViewModel.user.value?.nickname ?? "닉네임")
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - LifeCycle
    override func loadView() {
        self.view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }

    // MARK: - Bindings
    private func bindViewModel() {

        // MARK: - 프로필 유저 사진
        homeViewModel.user
            .compactMap { $0?.profileImageURL }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
            .drive(onNext: { [weak self] urlString in
                guard let self = self else { return }
                guard let url = URL(string: urlString) else { return }
                
                DispatchQueue.main.async {
                    self.customView.profileImageView.setImage(with: url)
                }
            }).disposed(by: disposeBag)
        
        // MARK: - 프로필 컬렉션 셀
        homeViewModel.transform()
            .allPostsByDate
            .map { dict -> [Post] in
                // 1) 날짜 키 내림차순 정렬
                let sortedKeys = dict.keys.sorted(by: >)
                // 2) 각 키의 [Post]를 꺼내서 하나의 배열로 합치기
                return sortedKeys
                    .compactMap { dict[$0] }
                    .flatMap { $0 }
                    .filter { $0.userId == self.homeViewModel.user.value?.uid }
            }
            .drive(customView.collectionView.rx.items(
                cellIdentifier: ProfilePostCell.identifier,
                cellType: ProfilePostCell.self)
            ) { _, post, cell in
                cell.configure(with: post)
            }
            .disposed(by: disposeBag)
        
        // MARK: - 프로필 컬렉션 셀 터치
        customView.collectionView.rx.modelSelected(Post.self)
            .asDriver()
            .drive(onNext: { [weak self] post in
                guard let self = self else { return }
                self.coordinator?.startFeedDetail(post: post)
            })
            .disposed(by: disposeBag)
        
        
        // MARK: - 카메라 버튼 탭
        customView.profileImageView.onCameraTapped = { [weak self] in
                guard let self = self else { return }
                self.presentImagePicker(sourceType: .photoLibrary)
        }
        
        // MARK: - 프로필 버튼 탭
        customView.profileImageView.onProfileTapped = { [weak self] in
            guard let self = self else { return }

            guard let image = self.customView.profileImageView.image else {
                print("이미지가 없습니다.")
                return
            }

            let previewVC = ImagePreViewController(image: image)
            previewVC.modalPresentationStyle = .fullScreen
            self.present(previewVC, animated: true)
        }
        
        // MARK: - 닉네임 수정 버튼 탭
        customView.editButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.coordinator?.startNicknameEdit()
            }).disposed(by: disposeBag)
        
        // MARK: - 닉네임 변경 감지
        homeViewModel.user
            .compactMap { $0?.nickname }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "홍길동")
            .drive(onNext: { [weak self] nickname in
                guard let self = self else { return }
                self.customView.nicknameLabel.text = nickname
            })
            .disposed(by: disposeBag)
    }
}


extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            print("❌ 해당 소스타입 사용 불가")
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }

    // 이미지 선택 완료
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage {
            
            // MARK: - 새 이미지 바로 반영 (사용자 경험 향상)
            self.customView.profileImageView.setImage(image)
            self.setPopGestureEnabled(false)     // <-- 제스처 막기
            self.showLoadingIndicator()
            
            // MARK: - 이미지 비동기 업로드
            profileViewModel.uploadImage(image: image)
                .bind(onNext: { [weak self] success in
                    guard let self = self else { return }
                    self.hideLoadingIndicator()
                    self.setPopGestureEnabled(true)  // <-- 다시 허용
                    if success {
                        if let profileViewModel = self.profileViewModel as? ProfileViewModel {
                            let updatedUser = profileViewModel.userRelay.value
                            self.homeViewModel.user.accept(updatedUser)

                            guard let groupId = homeViewModel.group.value?.groupId else { return }
                            self.homeViewModel.fetchGroup(groupId: groupId)
                        }
                    } else {
                        print("❌ 프로필 이미지 업로드 실패")
                    }
                }).disposed(by: disposeBag)
        }
    }

    // 선택 취소
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension ProfileViewController {
    
    // MARK: - 제스처 잠금/해제
    private func setPopGestureEnabled(_ enabled: Bool) {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = enabled
    }
    
    private func showLoadingIndicator() {
        guard let rootView = self.navigationController?.view ?? self.view else { return }
        let loadingView = UIView()
        loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        loadingView.isUserInteractionEnabled = true
        loadingView.translatesAutoresizingMaskIntoConstraints = false

        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        loadingView.addSubview(indicator)

        rootView.addSubview(loadingView)
        self.customView.loadingView = loadingView

        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: rootView.topAnchor),
            loadingView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
            loadingView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),

            indicator.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor)
        ])
    }

    
    private func showLoadingIndicator_noNavi() {
         let loadingView = UIView(frame: view.bounds)
         loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
         loadingView.isUserInteractionEnabled = true
         
         let indicator = UIActivityIndicatorView(style: .large)
         indicator.center = loadingView.center
         indicator.startAnimating()
         
         loadingView.addSubview(indicator)
         view.addSubview(loadingView)
        self.customView.loadingView = loadingView
     }
     
     private func hideLoadingIndicator() {
         customView.loadingView?.removeFromSuperview()
         customView.loadingView = nil
     }
}


#Preview {
    ProfileViewController(profileViewModel: StubProfileViewModel(),
                          homeViewModel: StubHomeViewModel(),
                          loginViewModel: StubLoginViewModel())
}
