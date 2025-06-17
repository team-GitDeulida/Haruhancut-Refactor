//
//  AppCoordinator.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import UIKit
import RxSwift
import RxRelay

protocol Coordinator: AnyObject {
    var parentCoordinator: Coordinator? { get set }
    var childCoordinators: [Coordinator] { get set }
    func start()
}

/// 모든 Coordinator가 제공 받는 기능
extension Coordinator {
    
    /// 자식 코디네이터가 자신의 플로우를 마쳤을 때, 부모가 자기 배열에서 제거하는 역할
    /// - Parameter child: 자식 코디네이터
    /// -    /// parentCoordinator?.childDidFinish(self)
    func childDidFinish(_ child: Coordinator?) {
        guard let child = child else { return }
        childCoordinators.removeAll() { $0 === child }
    }
}

final class AppCoordinator: Coordinator {

    /// protocol
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    var isLoggedIn: Bool = false
    
    func start() {
        print("AppCoordinator - start()")
        if isLoggedIn {
            startHomeCoordinator()
        } else {
            startLoginFlowCoordinator()
        }
    }
    
    func startLoginFlowCoordinator() {
        
    }
    
    func startHomeCoordinator() {
        
    }
}

final class LoginFlowCoordinator: Coordinator {
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
//    let navigationController: UINavigationController
//
//    init(navigationController: UINavigationController, loginViewModel: LoginViewModel) {
//        print("LoginFlowCoordinator - 생성")
//        self.navigationController = navigationController
//        self.loginViewModel = loginViewModel
//    }
    
    func start() {
        
    }
    
//    
//    deinit {
//        print("LoginCoordinator - 해제")
//    }
//    
//    func start() {
//        print("LoginCoordinator - start()")
//        showLogin()
//    }
}
