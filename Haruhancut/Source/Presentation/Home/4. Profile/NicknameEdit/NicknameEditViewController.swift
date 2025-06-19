//  NicknameEditViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/19/25.
//

import UIKit
import RxSwift

final class NicknameEditViewController: UIViewController {
    weak var coordinator: HomeCoordinator?
    private let loginViewModel: LoginViewModelType
    private let customView = NicknameEditView()
    private let disposeBag = DisposeBag()
    
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
        setNavigation()
        bindViewModel()
    }
    
    // MARK: - setNavigation
    private func setNavigation() {
        let backItem = UIBarButtonItem()
        backItem.title = "뒤로가기"
        navigationItem.backBarButtonItem = backItem
        navigationController?.navigationBar.tintColor = .mainWhite
    }

    // MARK: - Bindings
    private func bindViewModel() {
        let input = LoginViewModel.NicknameEditInput(nickmaneText: customView.textField.rx.text.orEmpty.asObservable(),
                                                     endBtnTapped: customView.endButton.rx.tap.asObservable())
        
        let output = loginViewModel.transform(input: input)
        
        /// 닉네임 유효성에 따라 버튼의 UI 상태 업데이트
        output.isNicknameValid
            .drive(onNext: { [weak self] isValid in
                guard let self else { return }
                self.customView.endButton.isEnabled = isValid
                self.customView.endButton.alpha = isValid ? 1 : 0.5
            }).disposed(by: disposeBag)
        
        /// 닉네임 변경 성공시 뒤로가기, 실패시 알림 및 뒤로가기
        output.nicknameChangeResult
            .drive(onNext: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    self.navigationController?.popViewController(animated: true)
                    AlertManager.showAlert(on: self, title: "에러: \(error)", message: "닉네임 변경 실패:\n\(error)")
                }
            }).disposed(by: disposeBag)
        
        /// return키 누르면 키보드 내려감
        customView.textField.rx.controlEvent(.editingDidEndOnExit)
            .asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.view.endEditing(true)
            }).disposed(by: disposeBag)
    }
}

#Preview {
    NicknameEditViewController(loginViewModel: StubLoginViewModel())
}
