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
    let navigationController: UINavigationController
    var isLoggedIn: Bool = false
    private let loginViewModel = LoginViewModel(loginUseCase: DIContainer.shared.resolve(LoginUsecase.self))
    
    init(navigationController: UINavigationController, isLoggedIn: Bool) {
        self.navigationController = navigationController
        self.isLoggedIn = isLoggedIn
        
        // MARK: - 알림 등록
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleForceLogout),
                                               name: .userForceLoggedOut,
                                               object: nil)
    }
    
    /// 로그인플로우 or 홈 플로우
    func start() {
        print("AppCoordinator - start()")
        if isLoggedIn {
            startHomeCoordinator()
        } else {
            startLoginFlowCoordinator()
        }
    }
    
    /// 로그인 플로우
    func startLoginFlowCoordinator() {
        let coordinator = LoginFlowCoordinator(
            navigationController: navigationController,
            loginViewModel: loginViewModel)
        coordinator.parentCoordinator = self
        childCoordinators.append(coordinator)
        coordinator.start()
    }
    
    /// 홈 플로우
    func startHomeCoordinator() {
        let homeViewModel = HomeViewModel()
        
        let coordinator = HomeCoordinator(
            navigationController: navigationController,
            loginViewModel: loginViewModel,
            homeViewModel: homeViewModel)
        coordinator.parentCoordinator = self
        childCoordinators.append(coordinator)
        coordinator.start()
    }
    
    /// 강제 로그아웃
    @objc private func handleForceLogout() {
        print("서버에서 예기치 않게 유저가 삭제되었습니다. 로그아웃 후 로그인 플로우 재시작합니다.")
        
        // 자식 코디네이터 정리
        childCoordinators.forEach { $0.parentCoordinator = nil }
        childCoordinators.removeAll()
        
        // 루트 화면에 애니메이션으로 로그인 흐름 다시 시작
        UIView.transition(with: navigationController.view,
                          duration: 0.4,
                          options: .transitionFlipFromLeft) {
            self.startLoginFlowCoordinator()
        }
    }
    
    // TODO: -
    private func checkAppVersion() {
        
    }
}

final class LoginFlowCoordinator: Coordinator {
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController
    private let loginViewModel: LoginViewModelType

    init(navigationController: UINavigationController, loginViewModel: LoginViewModelType) {
        print("LoginFlowCoordinator - 생성")
        self.navigationController = navigationController
        self.loginViewModel = loginViewModel
    }
    
    func start() {
        print("LoginCoordinator - start()")
        showLogin()
    }
    
    
    /// 로그인화면
    func showLogin() {
        let loginVC = LoginViewController(loginViewModel: loginViewModel)
        loginVC.coordinator = self
        navigationController.setViewControllers([loginVC], animated: true)
    }
    
    /// 닉네임 설정화면
    func showNicknameSetting() {
        let nickVC = NicknameSettingViewController(loginViewModel: loginViewModel)
        nickVC.coordinator = self
        navigationController.setViewControllers([nickVC], animated: true)
    }
    
    func showBirthdaySetting() {
        let birthVC = BirthdaySettingViewController(loginViewModel: loginViewModel)
        birthVC.coordinator = self
        navigationController.setViewControllers([birthVC], animated: true)
    }
    
    func showProfileSetting() {
        let profileVC = ProfileSettingViewController(loginViewModel: loginViewModel)
        profileVC.coordinator = self
        navigationController.setViewControllers([profileVC], animated: true)
    }
    
    func showHome() {
        finishFlow() // 현재 흐름 종료(자신을 부모에서 제거
        if let appCoordinator = parentCoordinator as? AppCoordinator {
            // ✅ AppCoordinator가 홈 코디네이터 시작
            appCoordinator.startHomeCoordinator()
        }
    }
    
    func finishFlow() {
        parentCoordinator?.childDidFinish(self)
    }
    
    deinit {
        print("LoginCoordinator - 해제")
    }
    
    
}

final class HomeCoordinator: Coordinator {
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController
    private let loginViewModel: LoginViewModel
    private let homeViewModel:  HomeViewModel
    
    init(navigationController: UINavigationController,
         loginViewModel: LoginViewModel,
         homeViewModel: HomeViewModel
    ) {
        self.navigationController = navigationController
        self.loginViewModel = loginViewModel
        self.homeViewModel = homeViewModel
    }
    
    func start() {
        // if let _ = loginViewModel.group.value {
        if let _ = loginViewModel.user.value?.groupId {
            /// 홈으로 이동
             startHome()
        } else {
            /// 그룹 생성
            // startGroup()
            print("그룹 생성")
            startHome()
        }
    }
    
    func startHome() {
        let homeVC = HomeViewController(viewModel: HomeViewModel())
        homeVC.coordinator = self
        navigationController.setViewControllers([homeVC], animated: true)
    }
}
