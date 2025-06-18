//  FeedViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import UIKit
import RxSwift

final class FeedViewController: UIViewController {
    weak var coordinator: HomeCoordinator?
    private let homeViewModel: HomeViewModelType
    private let customView = FeedView()
    private let disposeBag = DisposeBag()
    
    /// 이벤트 콜백 (Home에서 알람 울리기)
    var onPresentChooseAlert: ((UIAlertController) -> Void)?
    
    /// 이벤트 콜백 (Home에서 앨범 띄우기)
    var onPresenAlbum: ((UIViewController) -> Void)?
    
    // MARK: - Initializer
    init(homeViewModel: HomeViewModelType) {
        self.homeViewModel = homeViewModel
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
        addtarget()
        bindViewModel()
        setupLongPressGesture()
    }
    
    // MARK: - addTarget
    private func addtarget() {
        self.customView.cameraBtn.addTarget(self, action: #selector(startCamera), for: .touchUpInside)
    }

    // MARK: - Bindings
    private func bindViewModel() {
        /// 포스트 바인딩
        homeViewModel.transform().todayPosts
            .drive(customView.collectionView.rx.items(
                cellIdentifier: FeedCell.reuseIdentifier,
                cellType: FeedCell.self)
            ) { _, post, cell in
                cell.configure(post: post)
            }
            .disposed(by: disposeBag)
    }
}


// MARK: - 카메라 버튼 클릭
extension FeedViewController {
    /// 카메라 버튼 클릭(카메라 or 앨범 선택 가능 알림창)
    @objc private func startCamera() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // 📷 사진 촬영
        alert.addAction(UIAlertAction(title: "카메라로 찍기", style: .default) { [weak self] _ in
             self?.coordinator?.startCamera()
        })

        // 🖼️ 앨범에서 선택
        alert.addAction(UIAlertAction(title: "앨범에서 선택", style: .default) { [weak self] _ in
             self?.presentImagePicker(sourceType: .photoLibrary)
        })

        // ❌ 취소
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        /// 직접 present 대신 콜백 위임!
        if let presentAlert = onPresentChooseAlert {
            presentAlert(alert)
        } else {
            // 혹시나 없으면 fallback (단, 이 경우는 hierarchy 경고 가능성 있음)
            present(alert, animated: true)
        }
    }
}

// MARK: - 앨범 선택 관련
extension FeedViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            print("❌ 해당 소스타입 사용 불가")
            return
        }
        
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = false
        
        // 부모에게 위임해서 present!
        if let presentAction = onPresenAlbum {
            presentAction(picker)
        } else {
            // 없으면 fallback (이 경우 경고 발생 가능)
            present(picker, animated: true)
        }
        
        // 이미지 선택 완료
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)

            if let image = info[.originalImage] as? UIImage {
                // ✅ 기존 업로드 흐름과 동일하게 처리
                coordinator?.startToUpload(image: image, cameraType: .gallary)
            }
        }
        
        // 선택 취소
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - 롱프레스 핸들러
extension FeedViewController {
    
    /// 1. 컬렉션뷰에 롱프레스 핸들러 설정
    private func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self,
                                                            action: #selector(handleLongPress(_:)))
        customView.collectionView.addGestureRecognizer(longPressGesture)
    }
    
    /// 2. 롱프레스 메서드
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return } // 제스처가 시작될 때만 처리
        let location = gesture.location(in: customView.collectionView)
        guard let indexPath = customView.collectionView.indexPathForItem(at: location),
              indexPath.item < homeViewModel.posts.value.count else { return }
        
        // 1) 오늘 날짜 포스트만 뽑아서
        let todayPosts = homeViewModel.posts
            .value
            .filter { $0.isToday }

        // 2) indexPath.item이 오늘 포스트 배열 범위 안에 있는지 체크
        guard indexPath.item < todayPosts.count else { return }

        // 3) 거기서 해당 post를 꺼내서
        let post = todayPosts[indexPath.item]
        
        // 다른 사람 포스트면 삭제 불가
        guard post.userId == homeViewModel.user.value?.uid else {
            print("❌ 다른 사람의 게시물은 삭제할 수 없습니다.")
            return
        }

        let cancel = UIAlertAction(title: "취소", style: .cancel)
        let delete = UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.homeViewModel.deletePost(post)
        }
        
        let alert = UIAlertController(title: "삭제 확인", message: "이 사진을 삭제하시겠습니까?", preferredStyle: .alert)
        alert.addAction(delete)
        alert.addAction(cancel)
        if let presentAlert = onPresentChooseAlert {
            presentAlert(alert)
        }
    }
}

#Preview {
    FeedViewController(homeViewModel: StubHomeViewModel())
}
