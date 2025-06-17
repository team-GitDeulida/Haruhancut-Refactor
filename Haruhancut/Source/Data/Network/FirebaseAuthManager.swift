//
//  FirebaseAuthManager.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//
import FirebaseAuth
import FirebaseDatabase
import RxSwift
import RxCocoa

enum ProviderID: String {
    case kakao
    case apple
    var authProviderID: AuthProviderID {
        switch self {
        case .kakao: return .custom("oidc.kakao")
        case .apple: return .apple
        }
    }
}

protocol FirebaseAuthManagerProtocol {
    func setValue<T: Encodable>(path: String, value: T) -> Observable<Bool>      // create
    func readValue<T: Decodable>(path: String, type: T.Type) -> Observable<T>    // read
    func updateValue<T: Encodable>(path: String, value: T) -> Observable<Bool>   // update
    func deleteValue(path: String) -> Observable<Bool>                           // dellete
    
    func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Observable<Result<Void, LoginError>>
    func registerUserToRealtimeDatabase(user: User) -> Observable<Result<User, LoginError>>
}

final class FirebaseAuthManager: FirebaseAuthManagerProtocol {
    static let shared = FirebaseAuthManager()
    private init() {}
    private var databaseRef: DatabaseReference {
        Database.database(url: "https://haruhancut-kor-default-rtdb.firebaseio.com").reference()
    }
}

// MARK: - Realtime Database 제네릭 함수
extension FirebaseAuthManager {
    
    /// Create or Overwrite
    /// - Parameters:
    ///   - path: 경로
    ///   - value: 값
    /// - Returns: Observable<Bool>
    func setValue<T: Encodable>(path: String, value: T) -> Observable<Bool> {
        return Observable.create { observer in
            do {
                let data = try JSONEncoder().encode(value)
                let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                self.databaseRef.child(path).setValue(dict) { error, _ in
                    if let error = error {
                        print("🔥 setValue 실패: \(error.localizedDescription)")
                        observer.onError(error)
                    } else {
                        observer.onNext(true)
                    }
                    observer.onCompleted()
                }
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }
    
    /// Read - 1회 요청
    /// - Parameters:
    ///   - path: 경로
    ///   - type: 값
    /// - Returns: Observable<T>
    func readValue<T: Decodable>(path: String, type: T.Type) -> Observable<T> {
        return Observable.create { observer in
            self.databaseRef.child(path).observeSingleEvent(of: .value) { snapshot in
                guard let value = snapshot.value else {
                    observer.onError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "값이 존재하지 않음"]))
                    return
                }
                // print("🔥 observeValue snapshot.value = \(value)")
                
                do {
                    let data = try JSONSerialization.data(withJSONObject: value, options: [])
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    observer.onNext(decoded)
                } catch {
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    /// Firebase Realtime Database의 해당 경로에 있는 데이터를 일부 필드만 병합 업데이트합니다.
    /// - 기존 데이터는 유지하면서, 전달한 값의 필드만 갱신됩니다.
    ///
    /// 예: 댓글에 'text'만 수정할 때 유용
    ///
    /// - Parameters:
    ///   - path: 업데이트할 Firebase 경로
    ///   - value: 업데이트할 일부 필드를 가진 값 (Encodable → Dictionary로 변환됨)
    /// - Returns: 업데이트 성공 여부를 방출하는 Observable<Bool>
    func updateValue<T: Encodable>(path: String, value: T) -> Observable<Bool> {
        return Observable.create { observer in
            guard let dict = value.toDictionary() else {
                observer.onNext(false)
                observer.onCompleted()
                return Disposables.create()
            }
            
            self.databaseRef.child(path).updateChildValues(dict) { error, _ in
                if let error = error {
                    print("❌ updateValue 실패: \(error.localizedDescription)")
                    observer.onNext(false)
                } else {
                    // print("✅ updateValue 성공: \(path)")
                    observer.onNext(true)
                }
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }

    /// Delete
    /// - Parameter path: 삭제할 Firebase realtime 데이터 경로
    /// - Returns: 삭제 성공 여부 방출하는 Observable<Bool>
    func deleteValue(path: String) -> Observable<Bool> {
        return Observable.create { observer in
            self.databaseRef.child(path).removeValue { error, _ in
                if let error = error {
                    print("❌ deleteValue 실패: \(error.localizedDescription)")
                    observer.onNext(false)
                } else {
                    print("✅ deleteValue 성공: \(path)")
                    observer.onNext(true)
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}

// MARK: - 유저 관련
extension FirebaseAuthManager {
    
    /// Firebase Auth에 소셜 로그인으로 인증 요청
    /// - Parameters:
    ///   - prividerID: .kakao, .apple
    ///   - idToken: kakaoToken, appleToken
    /// - Returns: Result<Void, LoginError>
    func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Observable<Result<Void, LoginError>> {
        guard let provider = ProviderID(rawValue: prividerID) else {
            return Observable.just(.failure(LoginError.signUpError))
        }
        
        let credential = OAuthProvider.credential(
            providerID: provider.authProviderID,
            idToken: idToken,
            rawNonce: rawNonce ?? "")
        
        return Observable.create { observer in
            Auth.auth().signIn(with: credential) { _, error in
                
                if let error = error {
                    print("❌ Firebase 인증 실패: \(error.localizedDescription)")
                    observer.onNext(.failure(LoginError.signUpError))
                } else {
                    observer.onNext(.success(()))
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    /// Firebase Realtime Database에 유저 정보를 저장하고, 저장된 User를 반환
    /// - Parameter user: 저장할 User 객체
    /// - Returns: Result<User, LoginError>
    func registerUserToRealtimeDatabase(user: User) -> Observable<Result<User, LoginError>> {
//        return Observable.create { observer in
//            
//            // 1. Firebase UID확인
//            guard let firebaseUID = Auth.auth().currentUser?.uid else {
//                observer.onNext(.failure(.authError))
//                observer.onCompleted()
//                return Disposables.create()
//            }
//        }
        return .just(.failure(.authError))
    }
}




extension Encodable {
    func toDictionary() -> [String: Any]? {
        do {
            let data = try JSONEncoder().encode(self)
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            return jsonObject as? [String: Any]
        } catch {
            print("❌ toDictionary 변환 실패: \(error)")
            return nil
        }
    }
}

extension Decodable {
    static func fromDictionary(_ dict: [String: Any]) -> Self? {
        do {
            let data = try JSONSerialization.data(withJSONObject: dict)
            let decodedObject = try JSONDecoder().decode(Self.self, from: data)
            return decodedObject
        } catch {
            print("❌ fromDictionary 변환 실패: \(error)")
            return nil
        }
    }
}
