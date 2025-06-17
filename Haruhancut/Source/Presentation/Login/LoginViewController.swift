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
    private let viewModel: LoginViewModelType
    private let customView = LoginView()
    
    // MARK: - Initializer
    init(viewModel: LoginViewModelType) {
        self.viewModel = viewModel
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
        customView.animationView.play()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }   

    // MARK: - Bindings
    private func bindViewModel() {

    }
}

#Preview {
    LoginViewController(viewModel: StubLoginViewModel())
}
