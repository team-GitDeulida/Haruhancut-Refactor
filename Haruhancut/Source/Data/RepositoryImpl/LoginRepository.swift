//
//  LoginRepository.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import Foundation
import RxSwift
import FirebaseAuth
import FirebaseDatabase
import UIKit

protocol LoginRepositoryProtocol {
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

final class LoginRepository: LoginRepositoryProtocol {
    
    private let kakaoLoginManager: KakaoLoginManagerProtocol
    private let appleLoginManager: AppleLoginManagerProtocol
    private let firebaseAuthManager: FirebaseAuthManagerProtocol
    private let firebaseStorageManager: FirebaseStorageManagerProtocol
    
    init(
        kakaoLoginManager: KakaoLoginManagerProtocol,
        appleLoginManager: AppleLoginManagerProtocol,
        firebaseAuthManager: FirebaseAuthManagerProtocol,
        firebaseStorageManager: FirebaseStorageManagerProtocol
    ) {
        self.kakaoLoginManager = kakaoLoginManager
        self.appleLoginManager = appleLoginManager
        self.firebaseAuthManager = firebaseAuthManager
        self.firebaseStorageManager = firebaseStorageManager
    }
    
    func loginWithKakao() -> RxSwift.Observable<Result<String, LoginError>> {
        kakaoLoginManager.login()
    }
    
    func loginWithApple() -> RxSwift.Observable<Result<(String, String), LoginError>> {
        appleLoginManager.login()
    }
    
    func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> RxSwift.Observable<Result<Void, LoginError>> {
        return firebaseAuthManager.authenticateUser(prividerID: prividerID, idToken: idToken, rawNonce: rawNonce)
    }
    
    func registerUserToRealtimeDatabase(user: User) -> RxSwift.Observable<Result<User, LoginError>> {
        return firebaseAuthManager.registerUserToRealtimeDatabase(user: user)
    }
    
    func fetchUserInfo() -> RxSwift.Observable<User?> {
        return firebaseAuthManager.fetchMyInfo()
    }
    
    func fetchUser(uid: String) -> RxSwift.Observable<User?> {
        return firebaseAuthManager.fetchUser(uid: uid)
    }
    
    func updateUser(user: User) -> RxSwift.Observable<Result<User, LoginError>> {
        return firebaseAuthManager.updateUser(user: user)
    }
    
    func deleteUser(uid: String) -> RxSwift.Observable<Bool> {
        return firebaseAuthManager.deleteUser(uid: uid)
    }
    
    func uploadImage(user: User, image: UIImage) -> RxSwift.Observable<Result<URL, LoginError>> {
       
        let path = "users/\(user.uid)/profile.jpg"
        return firebaseStorageManager.uploadImage(image: image, path: path)
            .map { url in
                if let url = url {
                    return .success(url)
                } else {
                    return .failure(.signUpError)
                }
            }
    }
}
