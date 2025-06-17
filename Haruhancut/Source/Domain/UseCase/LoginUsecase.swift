//
//  LoginUsecase.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import RxSwift
import UIKit

protocol LoginUsecaseProtocol {
    func loginWithKakao() -> Observable<Result<String, LoginError>>
    func loginWithApple() -> Observable<Result<(String, String), LoginError>>
    func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Observable<Result<Void, LoginError>>
    func registerUserToRealtimeDatabase(user: User) -> RxSwift.Observable<Result<User, LoginError>>
    func fetchUserInfo() -> Observable<User?>
    func fetchUser(uid: String) -> Observable<User?>
    func updateUser(user: User) -> Observable<Result<User, LoginError>>
    func deleteUser(uid: String) -> Observable<Bool>
    func uploadImage(user: User, image: UIImage) -> Observable<Result<URL, LoginError>>
}

final class LoginUsecase: LoginUsecaseProtocol {
 
    
    
    private let repository: LoginRepositoryProtocol
    
    init(repository: LoginRepositoryProtocol) {
        self.repository = repository
    }
    
    /// 카카오 로그인
    /// - Returns: 카카오 로그인 토큰
    func loginWithKakao() -> Observable<Result<String, LoginError>>  {
        return repository.loginWithKakao()
    }
    
    /// 애플 로그인
    /// - Returns: 애플 로그인 토큰
    func loginWithApple() -> Observable<Result<(String, String), LoginError>> {
        return repository.loginWithApple()
    }
    
    /// Firebase Auth에 소셜 로그인으로 인증 요청
    /// - Parameters:
    ///   - prividerID: .kakao, .apple
    ///   - idToken: kakaoToken, appleToken
    /// - Returns: Result<Void, LoginError>
    func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Observable<Result<Void, LoginError>> {
        return repository.authenticateUser(prividerID: prividerID, idToken: idToken, rawNonce: rawNonce)
    }
    
    /// Firebase Realtime Database에 유저 정보를 저장하고, 저장된 User를 반환
    /// - Parameter user: 저장할 User 객체
    /// - Returns: Result<User, LoginError>
    func registerUserToRealtimeDatabase(user: User) -> Observable<Result<User, LoginError>> {
        return repository.registerUserToRealtimeDatabase(user: user)
    }
    
    /// 본인 정보 불러오기
    /// - Returns: Observable<User?>
    func fetchUserInfo() -> Observable<User?> {
        return repository.fetchUserInfo()
    }
    
    /// uid로 멤버 정보 불러오기
    /// - Parameter uid: 유저 고유 식별자
    /// - Returns: Observable<User?>
    func fetchUser(uid: String) -> RxSwift.Observable<User?> {
        return repository.fetchUser(uid: uid)
    }
    
    /// 유저 업데이트
    /// - Parameter user: 유저
    /// - Returns: 성공유무
    func updateUser(user: User) -> Observable<Result<User, LoginError>> {
        return repository.updateUser(user: user)
    }
    
    /// 유조 석제
    /// - Parameter uid: 유저 고유 식별자
    /// - Returns: 삭제 유무
    func deleteUser(uid: String) -> Observable<Bool> {
        return repository.deleteUser(uid: uid)
    }
    
    /// 이미지 업로드
    /// - Parameters:
    ///   - user: 유저
    ///   - image: 이미지
    /// - Returns: 이미지url
    func uploadImage(user: User, image: UIImage) -> Observable<Result<URL, LoginError>> {
        return repository.uploadImage(user: user, image: image)
    }
}

final class StubLoginUsecase: LoginUsecaseProtocol {
    
    func loginWithKakao() -> Observable<Result<String, LoginError>> {
        return .just(.success("stub-token"))
    }
    
    func loginWithApple() -> Observable<Result<(String, String), LoginError>> {
        return .just(.success(("stub-token", "stub-token")))
    }
    
    func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> RxSwift.Observable<Result<Void, LoginError>> {
        return .just(.success(()))
    }
    
    func registerUserToRealtimeDatabase(user: User) -> RxSwift.Observable<Result<User, LoginError>> {
        return .just(.success(User(
            uid: "stub-uid",
            registerDate: .now,
            loginPlatform: .kakao,
            nickname: "stub-nickname",
            birthdayDate: .now, gender: .male,
            isPushEnabled: true)))
    }
    
    func fetchUserInfo() -> RxSwift.Observable<User?> {
        return .just(
            User(
            uid: "stub-uid",
            registerDate: .now,
            loginPlatform: .kakao,
            nickname: "stub-nickname",
            birthdayDate: .now, gender: .male,
            isPushEnabled: true)
        )
    }
    
    func fetchUser(uid: String) -> RxSwift.Observable<User?> {
        return .just(
            User(
            uid: "stub-uid",
            registerDate: .now,
            loginPlatform: .kakao,
            nickname: "stub-nickname",
            birthdayDate: .now, gender: .male,
            isPushEnabled: true)
        )
    }
    
    func updateUser(user: User) -> RxSwift.Observable<Result<User, LoginError>> {
        return .just(.success(User(
            uid: "stub-uid",
            registerDate: .now,
            loginPlatform: .kakao,
            nickname: "stub-nickname",
            birthdayDate: .now, gender: .male,
            isPushEnabled: true)))
    }
    
    func deleteUser(uid: String) -> RxSwift.Observable<Bool> {
        return .empty()
    }
    
    func uploadImage(user: User, image: UIImage) -> RxSwift.Observable<Result<URL, LoginError>> {
        return .just(.success(URL(string: "11")!))
    }
}
