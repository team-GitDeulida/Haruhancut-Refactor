//
//  SceneDelegate.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import UIKit
import ScaleKit
import FirebaseAuth
import KakaoSDKAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        // 1. scene 캡처
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // 1.1 화면 사이즈를 저장하는 커스텀 함수, 기기 해상도에 따라 레이아웃 사이즈 조절
        DynamicSize.setScreenSize(windowScene.screen.bounds)
        
        // 2. window scene을 가져오는 windowScene을 생성자를 사용해서 UIWindow를 생성
        let window = UIWindow(windowScene: windowScene)
        let navigationController = UINavigationController()
        
        // 3. view 계층을 프로그래밍 방식으로 만들기
        // let rootVC = NicknameSettingViewController(loginViewModel: StubLoginViewModel())
        
        // 로그인 여부 확인
        let isLoggedIn = Auth.auth().currentUser != nil && UserDefaultsManager.shared.loadUser() != nil
        let coordinator = AppCoordinator(navigationController: navigationController, isLoggedIn: isLoggedIn)
        self.appCoordinator = coordinator
        coordinator.start()
        
        // 4. viewController로 navigationController로 설정
        window.rootViewController = navigationController
        
        // 5. window를 설정하고 makeKeyAndVisible()
        self.window = window
        window.makeKeyAndVisible()
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        
        // 카카오 로그인
        if let url = URLContexts.first?.url {
            if (AuthApi.isKakaoTalkLoginUrl(url)) {
                _ = AuthController.rx.handleOpenUrl(url: url)
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    /// 앱이 포그라운드로 진입 (처음 실행도 포함)
    func sceneWillEnterForeground(_ scene: UIScene) {
        checkAppVersionIfNeeded()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}

// MARK: - 버전 업데이트 확인
extension SceneDelegate {
    private func checkAppVersionIfNeeded() {
        VersionManager.shared.checkForAppUpdates(appId: Constants.Appstore.appId) { [weak self] needsUpdate, currentVersion, latestVersion in
            guard needsUpdate, let latest = latestVersion else { return }

            DispatchQueue.main.async {
                guard let self = self,
                          let topVC = self.appCoordinator?.navigationController.topViewController else { return }

                let alert = UIAlertController(
                    title: "업데이트 알림",
                    message: "최신 버전(\(latest))이 출시되었습니다. 앱스토어에서 업데이트 해주세요.",
                    preferredStyle: .alert
                )

                alert.addAction(UIAlertAction(title: "업데이트", style: .default, handler: { _ in
                    if let url = URL(string: Constants.Appstore.appstoreURL) {
                        UIApplication.shared.open(url)
                    }
                }))

                topVC.present(alert, animated: true)
            }
        }
    }
}

