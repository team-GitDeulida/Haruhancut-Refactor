//
//  LoginError.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import Foundation

enum GroupError: Error {
    case makeHostError
    case fetchGroupError
}

enum LoginError: Error {
    
    // MARK: - kakao
    case noTokenKakao
    case sdkKakao(Error)
    
    // MARK: - apple
    case invalidCredential
    case sdkApple(Error)
    
    // MARK: - Auth
    case authError
    case signUpError
    case noUser
    case logoutError
    case updateUserError
    
    var description: String {
        switch self {
        case .noTokenKakao:
            "⚠️ 카카오 로그인 token이 없습니다"
        case .sdkKakao(let error):
            "⚠️ 카카오 SDK 오류: \(error)"
        case .invalidCredential:
            "⚠️ 애플 인증 오류"
        case .sdkApple(let error):
            "⚠️ 애플 SDK 오류: \(error)"
        case .authError:
            "⚠️ 파이어베이스 인증 실패"
        case .signUpError:
            "⚠️ 파이어베이스 가입 실패"
        case .noUser:
            "⚠️ 유저가 존재하지 않음"
        case .logoutError:
            "⚠️ 로그아웃 실패"
        case .updateUserError:
            "⚠️ 유저 업데이트 실패"
        }
    }
}
    
