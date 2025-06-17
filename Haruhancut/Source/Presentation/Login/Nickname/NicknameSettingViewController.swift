//  NicknameSettingViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import UIKit
import RxSwift
import RxCocoa

final class NicknameSettingViewController: UIViewController {
    weak var coordinator: LoginFlowCoordinator?
    private let disposeBag = DisposeBag()
    private let loginViewModel: LoginViewModelType
    private let customView = NicknameSettingView()
    
    // MARK: - Initializer
    init(loginViewModel: LoginViewModelType) {
        self.loginViewModel = loginViewModel
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
        let input = LoginViewModel.NicknameInput(
            nicknameText: customView.textField.rx.text.orEmpty.asObservable(),
            nextBtnTapped: customView.nextButton.rx.tap.asObservable())
        
        let output = loginViewModel.transform(input: input)
        
        /// 닉네임 유효성 검사에 따라 다음 버튼 활성화
        output.isNicknameValid
            .drive(onNext: { [weak self] isValid in
                guard let self = self else { return }
                self.customView.nextButton.isEnabled = isValid
                self.customView.nextButton.alpha = isValid ? 1.0 : 0.5
            })
            .disposed(by: disposeBag)
        
        /// return키 입력시 키보드 내려감
        customView.textField.rx.controlEvent(.editingDidEndOnExit)
            .bind(onNext: { [weak self] in
                guard let self = self else { return }
                self.view.endEditing(true)
            })
            .disposed(by: disposeBag)
        
        /// 다음 버튼이 눌렸음을 알려주는 이벤트 스트림
        output.moveToBirthday
            .drive(onNext: { _ in
                self.customView.endEditing(true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.coordinator?.showBirthdaySetting()
                }
            })
            .disposed(by: disposeBag)
    }
}

#Preview {
    NicknameSettingViewController(loginViewModel: StubLoginViewModel())
}
