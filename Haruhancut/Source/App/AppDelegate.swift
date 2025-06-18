//
//  AppDelegate.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import UIKit
import RxSwift

// 파이어베이스
import FirebaseCore
import FirebaseMessaging

// 카카오톡
import RxKakaoSDKCommon
import KakaoSDKAuth


@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var disposeBag = DisposeBag()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 파이어베이스 설정
        FirebaseApp.configure()
        
        // 앱 실행 시 사용자에게 알림 허용 권한 받기
        UNUserNotificationCenter.current().delegate = self /// UNUserNotificationCenterDelegate
        
        // 파이어베이스 Meesaging 설정
        Messaging.messaging().delegate = self /// MessagingDelegate
        
        // 알림 권한 호출
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            guard granted else { return }
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        
        // 카카오톡 설정
        if let nativeAppKey: String = Bundle.main.infoDictionary?["KAKAO_NATIVE_APP_KEY"] as? String {
            RxKakaoSDK.initSDK(appKey: nativeAppKey, loggingEnable: false)
        }
        
        // 의존성 주입
        self.registerDependencies()
        
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // 카카오톡 로그인
        if (AuthApi.isKakaoTalkLoginUrl(url)) {
            return AuthController.rx.handleOpenUrl(url: url)
        }
        
        return false
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {

    }
}

/*
 - DIContainer는 프로젝트 전반에서 객체를 주입받을 수 있도록 관리하는 싱글톤이다
 - UseCase 구현체를 등록한다
 */

extension AppDelegate {
    private func registerDependencies() {
        let kakaoLoginManager = KakaoLoginManager.shared
        let appleLoginManager = AppleLoginManager.shared
        let firebaseAuthManager = FirebaseAuthManager.shared
        let firebaseStorageManager = FirebaseStorageManager.shared
        
        let authRepository = LoginRepository(kakaoLoginManager: kakaoLoginManager, appleLoginManager: appleLoginManager, firebaseAuthManager: firebaseAuthManager, firebaseStorageManager: firebaseStorageManager)
        let loginUsecase = LoginUsecase(repository: authRepository)
        DIContainer.shared.register(LoginUsecase.self, dependency: loginUsecase)
        
        let groupRepository = GroupRepository(firebaseAuthManager: firebaseAuthManager,
                                              firebaseStorageManager: firebaseStorageManager)
        let groupUsecase = GroupUsecase(repository: groupRepository)
        DIContainer.shared.register(GroupUsecase.self, dependency: groupUsecase)
    }
}

// MARK: - FCM 알람관련
extension AppDelegate: UNUserNotificationCenterDelegate {
    // 백그라운드에서 푸시 알림을 탭했을 때 실행
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        // 1) APNs 토큰 등록
        Messaging.messaging().apnsToken = deviceToken
        
        // 2) Data → 16진수 문자열 변환
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let tokenString = tokenParts.joined()
        print("APNS token: \(tokenString)")
        
        // 3) 여기서 FCM 토큰 요청
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ FCM 토큰 요청 실패: \(error.localizedDescription)")
            } else if let token = token {
                print("✅ FCM 토큰 발급 완료: \(token)")
                UserDefaults.standard.set(token, forKey: "localFCMToken")
            }
        }
    }
    
    // 포그라운드(앱 켜진 상태)에서도 알림 오는 설정
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner])
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔥 받은 FCM 토큰: \(String(describing: fcmToken))")
        if let token = fcmToken {
            UserDefaults.standard.set(token, forKey: "localFCMToken")
        }
    }
}
