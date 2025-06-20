//  LoginViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import UIKit
import RxSwift

final class LoginViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    weak var coordinator: LoginFlowCoordinator?
    private let loginViewModel: LoginViewModelType
    private let customView = LoginView()
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkTutorialStatus()
        customView.animationView.play()
    }

    // MARK: - Bindings
    private func bindViewModel() {
        let input = LoginViewModel.LoginInput(
            kakaoLoginTapped: customView.kakaoLoginButton.rx.tap.asObservable(),
            appleLoginTapped: customView.appleLoginButton.rx.tap.asObservable())
        
        let output = loginViewModel.transform(input: input)
        output.loginResult
            .drive { result in
                switch result {
                case .success:
                    print("기존 회원 - 홈으로 화면전환")
                    self.coordinator?.showHome()
                case .failure(let error):
                    switch error {
                    case .noUser:
                        print("신규 회원 - 닉네임창으로 화면전환")
                        self.coordinator?.showNicknameSetting()
                    default:
                        print("bindViewModelOutput - 로그인 실패")
                    }
                }
            }.disposed(by: disposeBag)
    }
    
    /// 온보딩 체크
    private func checkTutorialStatus() {
        let userDefaults = UserDefaults.standard
        let hasCompletedTutorial = userDefaults.bool(forKey: "Tutorial")
        
        if !hasCompletedTutorial {
            let onboardingVC = OnboardingViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
            onboardingVC.modalPresentationStyle = .fullScreen
            present(onboardingVC, animated: false)
        }
    }
}

#Preview {
    LoginViewController(loginViewModel: StubLoginViewModel())
}
