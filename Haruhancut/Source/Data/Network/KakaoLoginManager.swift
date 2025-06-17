//
//  KakaoLoginManager.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import RxSwift
import KakaoSDKUser
import RxKakaoSDKUser

protocol KakaoLoginManagerProtocol {
    func login() -> Observable<Result<String, LoginError>>
}

final class KakaoLoginManager: KakaoLoginManagerProtocol {
    
    // MARK: - SingleTon
    static let shared = KakaoLoginManager()
    private init() {}
    
    /// 카카오 로그인
    /// - Returns: Id 토큰을 방출하는 스트림
    func login() -> Observable<Result<String, LoginError>>  {
        let loginObservable = UserApi.isKakaoTalkLoginAvailable() ?
        UserApi.shared.rx.loginWithKakaoTalk() : UserApi.shared.rx.loginWithKakaoAccount()
        
        return loginObservable
            .map { token in
                guard let idToken = token.idToken else {
                    return .failure(.noTokenKakao)
                }
                return .success(idToken)
            }
            .catch { error in
                return .just(.failure(.sdkKakao(error)))
            }
    }
}
