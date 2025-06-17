//  ProfileViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import UIKit
import RxSwift

final class ProfileSettingViewController: UIViewController {
    weak var coordinator: LoginFlowCoordinator?
    private let disposeBag = DisposeBag()
    private let loginViewModel: LoginViewModelType
    private let customView: ProfileSettingView
    
    // MARK: - Initializer
    init(loginViewModel: LoginViewModelType) {
        self.loginViewModel = loginViewModel
        let nickname = loginViewModel.user.value?.nickname ?? "닉네임"
        self.customView = ProfileSettingView(nickname: nickname)
        super.init(nibName: nil, bundle: nil)
        
        // MARK: - 프로필 피커 탭 콜백
        customView.onRequestPresentImagePicker = { [weak self] sourceType in
            self?.presentImagePicker(sourceType: sourceType)
        }
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
        let input = LoginViewModel.ProfileInput(
            selectedImage: customView.selectedRelay.asObservable(),
            nextBtnTapped: customView.nextButton.rx.tap.asObservable())
        
        let output = loginViewModel.transform(input: input)
        
        /// 버튼 탭 시 로딩 시작
        customView.nextButton.rx.tap
        .bind(onNext: { [weak self] in
            guard let self = self else { return }
            self.customView.activityIndicator.startAnimating()
            self.customView.nextButton.isEnabled = false
        }).disposed(by: disposeBag)
        
        
        /// 로그인 결과
        output.signUpResult
            .drive(onNext: { [weak self] result in
                guard let self = self else { return }
                /// 로딩 종료
                self.customView.activityIndicator.stopAnimating()
                self.customView.nextButton.isEnabled = true
                
                switch result {
                case .success:
                    coordinator?.showHome()
                case.failure(let error):
                    print("❌ [VC] 회원가입 실패: \(error)")
                }
            }).disposed(by: disposeBag)
    }
}

#Preview {
    ProfileSettingViewController(loginViewModel: StubLoginViewModel())
}

extension ProfileSettingViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
            // 이미지 설정
            self.customView.profileImageView.setImage(image)
            self.customView.selectedRelay.accept(image)
            // self.customView.selectedImage = image
        }
    }

    // 선택 취소
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
