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
        let homeViewModel = HomeViewModel(
            loginUsecase: DIContainer.shared.resolve(LoginUsecase.self),
            groupUsecase: DIContainer.shared.resolve(GroupUsecase.self),
            userRelay: loginViewModel.user
        )
        
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
        self.navigationController.setViewControllers([loginVC], animated: true)
    }
    
    /// 닉네임 설정화면
    func showNicknameSetting() {
        let nickVC = NicknameSettingViewController(loginViewModel: loginViewModel)
        nickVC.coordinator = self
        self.navigationController.setViewControllers([nickVC], animated: true)
    }
    
    func showBirthdaySetting() {
        let birthVC = BirthdaySettingViewController(loginViewModel: loginViewModel)
        birthVC.coordinator = self
        self.navigationController.setViewControllers([birthVC], animated: true)
    }
    
    func showProfileSetting() {
        let profileVC = ProfileSettingViewController(loginViewModel: loginViewModel)
        profileVC.coordinator = self
        self.navigationController.setViewControllers([profileVC], animated: true)
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
    private var groupViewModel: GroupViewModel?
    private let profileViewModel: ProfileViewModel
    
    // MARK: - 최초로 사용되는 순간에 딱 한 번만 초기화
    private lazy var memberViewModel: MemberViewModel = {
        return MemberViewModel(loginUsecase: DIContainer.shared.resolve(LoginUsecase.self),
                               membersRelay: homeViewModel.members
        )
    }()
    
    init(navigationController: UINavigationController,
         loginViewModel: LoginViewModel,
         homeViewModel: HomeViewModel
    ) {
        self.navigationController = navigationController
        self.loginViewModel = loginViewModel
        self.homeViewModel = homeViewModel
        self.profileViewModel = ProfileViewModel(loginUsecase: DIContainer.shared.resolve(LoginUsecase.self),
                                                 userRelay: loginViewModel.user)
    }
    
    func start() {
        // if let _ = loginViewModel.group.value {
        if let _ = loginViewModel.user.value?.groupId {
            /// 홈으로 이동
             startHome()
        } else {
            /// 그룹 생성
            startGroup()
        }
    }
    
    func startHome() {
        let homeVC = HomeViewController(homeViewModel: homeViewModel)
        homeVC.coordinator = self
        self.navigationController.setViewControllers([homeVC], animated: true)
        _ = memberViewModel
    }
    
    func startGroup() {
        groupViewModel = GroupViewModel(
            loginViewModel: loginViewModel,
            homeViewModel: homeViewModel,
            groupUsecase: DIContainer.shared.resolve(GroupUsecase.self))
        guard let groupVM = groupViewModel else { return }
        let vc = GroupViewController(groupViewModel: groupVM)
        vc.coordinator = self
        self.navigationController.setViewControllers([vc], animated: true)
    }
    
    func startGroupHost() {
        guard let groupVM = groupViewModel else { return }
        let vc = GroupHostViewController(groupViewModel: groupVM)
        vc.coordinator = self
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    func startGroupEnter() {
        guard let groupVM = groupViewModel else { return }
        let vc = GroupEnterViewController(groupViewModel: groupVM)
        vc.coordinator = self
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    func startCamera() {
        let vc = CameraViewController()
        vc.coordinator = self
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    func startToUpload(image: UIImage, cameraType: CameraType) {
        if cameraType == .camera {
            homeViewModel.cameraType = .camera
        } else {
            homeViewModel.cameraType = .gallary
        }
        
        let uploadVC = ImageUploadViewController(image: image,
                                                 homeViewModel: homeViewModel)
        uploadVC.coordinator = self
        self.navigationController.pushViewController(uploadVC, animated: true)
    }
    
    func backToHome() {
        // 쌓여있던 모든 화면 제거하고 루트인 homeVC로 이동
        self.navigationController.popToRootViewController(animated: true)
    }
    
    func startFeedDetail(post: Post) {
        let vc = FeedDetailViewController(homeViewModel: homeViewModel, post: post)
        vc.coordinator = self
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    func startMembers() {
        let vc = MemberViewController(memberviewModel: memberViewModel,
                                      homeViewModel: homeViewModel)
        vc.coordinator = self
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    func startComment(post: Post) {
        let vc = FeedCommentViewController(homeViewModel: homeViewModel, post: post)
        vc.modalPresentationStyle = .pageSheet
        self.navigationController.present(vc, animated: true)
    }
    
    func startProfile() {
        let vc = ProfileViewController(profileViewModel: profileViewModel,
                                       homeViewModel: homeViewModel,
                                       loginViewModel: loginViewModel)
        vc.coordinator = self
        self.navigationController.pushViewController(vc, animated: true)
    }
    
    func startNicknameEdit() {
        let vc = NicknameEditViewController(loginViewModel: loginViewModel)
        vc.coordinator = self
        self.navigationController.pushViewController(vc, animated: true)
    }
}
