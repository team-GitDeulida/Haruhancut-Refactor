//  LoginViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseMessaging

protocol LoginViewModelType {
    var user: BehaviorRelay<User?> { get }
    func transform(input: LoginViewModel.LoginInput) -> LoginViewModel.LoginOutput
    func transform(input: LoginViewModel.NicknameInput) -> LoginViewModel.NicknameOutput
    func transform(input: LoginViewModel.BirthdayInput) -> LoginViewModel.BirthdayOutput
    func transform(input: LoginViewModel.ProfileInput) -> LoginViewModel.ProfileOutput
    func transform(input: LoginViewModel.NicknameEditInput) -> LoginViewModel.NicknameEditOutput
}

final class LoginViewModel: LoginViewModelType {
    private let disposeBag = DisposeBag()
    private let loginUseCase: LoginUsecaseProtocol
    private(set) var token: String?
    
    // 로그인 이벤트 방출 트리거
    private let signUpResultRelay = PublishRelay<Result<Void, LoginError>>()
    
    // 유저
    var user = BehaviorRelay<User?>(value: nil)
    let isNewUser = BehaviorRelay<Bool>(value: false)
    
    init(loginUseCase: LoginUsecaseProtocol) {
        self.loginUseCase = loginUseCase
        
        // 1. 캐시 유저 있다면 불러오기(사용자 경험 향상)
        if let cachedUser = UserDefaultsManager.shared.loadUser() {
            self.user.accept(cachedUser)
            
            // 2. 서버에서 유저 불러오기
            self.fetchAndCachedUserInfo()
        }
    }
}

// MARK: - LoginVC
extension LoginViewModel {
    struct LoginInput {
        let kakaoLoginTapped: Observable<Void>
        let appleLoginTapped: Observable<Void>
    }
    
    struct LoginOutput {
        let loginResult: Driver<Result<Void, LoginError>>
    }
    
    func transform(input: LoginInput) -> LoginOutput {
        
        // MARK: - 카카오 로그인
        let kakaoResult = input.kakaoLoginTapped
            // 1. 카카오 토큰 발급
            .flatMapLatest { [weak self] _ -> Observable<Result<String, LoginError>> in
                guard let self = self else { return .empty() }
                return self.loginUseCase.loginWithKakao()
            }
            // 2. FirebaseAuth 인증
            .flatMapLatest { [weak self] result -> Observable<Result<Void, LoginError>> in
                guard let self = self else { return .empty() }
                switch result {
                case .success(let token):
                    self.token = token
                    return self.loginUseCase.authenticateUser(prividerID: "kakao", idToken: token, rawNonce: nil)
                case .failure(let error):
                    return .just(.failure(error))
                }
            }
            // 3. 기존유저: 정보가져오기. 신규유저: 회원가입
            .flatMapLatest { [weak self] result -> Observable<Result<Void, LoginError>> in
                guard let self = self else { return .empty() }
                switch result {
                case .success:
                    return self.loginUseCase.fetchUserInfo()
                        .map { user -> Result<Void, LoginError> in
                            if let user = user {
                                /// 기존 회원
                                self.user.accept(user)
                                UserDefaultsManager.shared.saveUser(user)
                                return .success(())
                            } else {
                                /// 신규 회원
                                self.user.accept(User.empty(loginPlatform: .kakao))
                                if let user = user {
                                    UserDefaultsManager.shared.saveUser(user)
                                }
                                return .failure(.noUser)
                            }
                        }
                case .failure(let error):
                    return .just(.failure(error))
                }
            }
            
            
        // MARK: - 애플 로그인
        let appleResult = input.appleLoginTapped
            // 1. 애플 토큰 발급
            .flatMapLatest { [weak self] _ -> Observable<Result<(String, String), LoginError>> in
                guard let self = self else { return .empty() }
                return self.loginUseCase.loginWithApple()
            }
            // 2. FirebaseAuth 인증
            .flatMapLatest { [weak self] result -> Observable<Result<Void, LoginError>> in
                guard let self = self else { return .empty() }
                switch result {
                case .success(let (token, rawNonce)):
                    self.token = token
                    return self.loginUseCase.authenticateUser(prividerID: "apple", idToken: token, rawNonce: rawNonce)
                case .failure(let error):
                    return .just(.failure(error))
                }
            }
            // 3. 기존유저: 정보가져오기. 신규유저: 회원가입
            .flatMapLatest { [weak self] result -> Observable<Result<Void, LoginError>> in
                guard let self = self else { return .empty() }
                switch result {
                case .success:
                    return self.loginUseCase.fetchUserInfo()
                        .map { user -> Result<Void, LoginError> in
                            if let user = user {
                                /// 기존 회원
                                self.user.accept(user)
                                UserDefaultsManager.shared.saveUser(user)
                                return .success(())
                            } else {
                                /// 신규 회원
                                self.user.accept(User.empty(loginPlatform: .apple))
                                if let user = user {
                                    UserDefaultsManager.shared.saveUser(user)
                                }
                                return .failure(.noUser)
                            }
                        }
                case .failure(let error):
                    return .just(.failure(error))
                }
            }
        
        let margedResult = Observable.merge(kakaoResult, appleResult)
            .asDriver(onErrorJustReturn: .failure(.signUpError))
        
        return LoginOutput(loginResult: margedResult)
    }
    
    private func fetchAndCachedUserInfo() {
        loginUseCase.fetchUserInfo()
            .bind(onNext: { [weak self] user in
                guard let self = self else { return }
                if let user = user {
                    self.user.accept(user)
                    UserDefaultsManager.shared.saveUser(user)
                    
                    // MARK: - FCM 토큰 동기화
                    self.syncFCMTokenWithServerIfNeeded(currentUser: user)
                } else {
                    print("❌ 사용자 정보 없음 캐시 삭제 진행")
                    self.user.accept(nil)
                    UserDefaultsManager.shared.removeUser()
                    UserDefaultsManager.shared.removeGroup()
                    
                    // 강제 로그아웃 유도
                    NotificationCenter.default.post(name: .userForceLoggedOut, object: nil)
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - NicknameVC
extension LoginViewModel {
    struct NicknameInput {
        let nicknameText: Observable<String>
        let nextBtnTapped: Observable<Void>
    }
    
    struct NicknameOutput {
        let isNicknameValid: Driver<Bool>
        let moveToBirthday: Driver<Void>
    }
    
    func transform(input: NicknameInput) -> NicknameOutput {
        let isNicknameValid = input.nicknameText
            /// 앞뒤 공백 제거 후, 한 글자라도 있으면 true
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).count != 0 }
            .distinctUntilChanged() /// 중복된 값은 무시하고 변경될 때만 아래로 전달
            .asDriver(onErrorJustReturn: false) /// 에러 발생 시에도 false를 대신 방출

        // 닉네임 다음 버튼 입력 이벤트 감지(viewModel이 구독)
        let moveToBirthday = input.nextBtnTapped
            .withLatestFrom(input.nicknameText)
            .do(onNext: { [weak self] nickname in
                guard let self = self else { return }
                if var currentUser = self.user.value {
                    currentUser.nickname = nickname
                    self.user.accept(currentUser)
                }
            })
            .map { _ in }
            .asDriver(onErrorDriveWith: .empty())
        
        return NicknameOutput(
            isNicknameValid: isNicknameValid,
            moveToBirthday: moveToBirthday)
    }
}

// MARK: - BirthVC
extension LoginViewModel {
    struct BirthdayInput {
        let birthdayDate: Observable<Date>
        let nextBtnTapped: Observable<Void>
    }
    
    struct BirthdayOutput {
        let moveToProfile: Driver<Void>
    }
    
    func transform(input: BirthdayInput) -> BirthdayOutput {
        let moveToProfile = input.nextBtnTapped
            .withLatestFrom(input.birthdayDate)
            .do(onNext: { [weak self] birthdayDate in
                guard let self = self else { return }
                if var currentUser = self.user.value {
                    currentUser.birthdayDate = birthdayDate
                    self.user.accept(currentUser)
                }
            })
            .map { _ in }
            .asDriver(onErrorJustReturn: ())
            
        return BirthdayOutput(moveToProfile: moveToProfile)
    }
}

// MARK: - ProfileSetVC
extension LoginViewModel {
    struct ProfileInput {
        let selectedImage: Observable<UIImage?>
        let nextBtnTapped: Observable<Void>
    }
    
    struct ProfileOutput {
        let signUpResult: Driver<Result<Void, LoginError>>
    }
    
    func transform(input: ProfileInput) -> ProfileOutput {
        let signUpResult = signUpResultRelay
            .asDriver(onErrorJustReturn: .failure(.signUpError))
        
        input.nextBtnTapped
            .withLatestFrom(input.selectedImage)
            .flatMapLatest { [weak self] image -> Observable<Result<Void, LoginError>> in
                guard let self = self,
                      let currentUser = self.user.value else {
                    return .just(.failure(.signUpError))
                }
                // 1) FCM 토큰 발급
                return self.generateFCMToken()
                .flatMapLatest { token -> Observable<Result<Void, LoginError>> in
                    
                    // 2) User 모델에 토큰 저장
                    var userWithToken = currentUser
                    userWithToken.fcmToken = token
                    self.user.accept(userWithToken)
                    
                    // 3) 기존 회원가입 + 이미지 업로드 로직
                    return self.registerUser(user: userWithToken)
                        .flatMap { result -> Observable<Result<Void, LoginError>> in
                            switch result {
                            case .success:
                                guard let user = self.user.value else {
                                    return .just(.failure(.signUpError))
                                }
                                
                                // 4. 이미지가 있다면
                                if let image = image {
                                    return self.loginUseCase
                                        .uploadImage(user: user, image: image)
                                        .flatMap { uploadResult -> Observable<Result<Void, LoginError>> in
                                            switch uploadResult {
                                            case .success(let url):
                                                var updated = user
                                                updated.profileImageURL = url.absoluteString
                                                UserDefaultsManager.shared.saveUser(updated)
                                                
                                                return self.loginUseCase.updateUser(user: updated)
                                                    .map { [weak self] result -> Result<Void, LoginError> in
                                                        guard let self = self else { return .failure(.signUpError) }
                                                        if case .success(let newUser) = result {
                                                            self.user.accept(newUser)
                                                            UserDefaultsManager.shared.saveUser(newUser)
                                                        }
                                                        return result.mapToVoid()
                                                    }
                                            case .failure(let error):
                                                return .just(.failure(error))
                                            }
                                        }
                                } else {
                                    print("이미지 없음")
                                    return .just(.success(()))
                                }
                                
                            case .failure(let error):
                                return .just(.failure(error))
                            }
                        }
                }
            }
            .bind(to: signUpResultRelay)
            .disposed(by: disposeBag)
        
        return ProfileOutput(signUpResult: signUpResult)
    }
    
    private func registerUser(user: User) -> Observable<Result<Void, LoginError>> {
        loginUseCase
            .registerUserToRealtimeDatabase(user: user)
            .map { [weak self] result -> Result<Void, LoginError> in
                if case .success(let user) = result {
                    self?.user.accept(user)
                    UserDefaultsManager.shared.saveUser(user)
                }
                return result.mapToVoid()
            }
    }
}

// MARK: - NicknameEdit
extension LoginViewModel {
    struct NicknameEditInput {
        let nickmaneText: Observable<String>
        let endBtnTapped: Observable<Void>
    }
    
    struct NicknameEditOutput {
        let isNicknameValid: Driver<Bool>
        let nicknameChangeResult: Driver<Result<Void, LoginError>>
    }
    
    func transform(input: NicknameEditInput) -> NicknameEditOutput {
        /// 닉네임 유효성
        let isNicknameValid = input.nickmaneText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).count != 0 }
            .distinctUntilChanged()             /// 중복된 값은 무시하고 변경될 때만 다음 연산자 실행
            .asDriver(onErrorJustReturn: false) /// 에러 없이 UI 바인딩용으로 적절한 Driver<Bool>로 변환
        
        /// 닉네임 변경 결과
        let endBtnTapped = input.endBtnTapped   /// 완료 버튼이 눌렸을 때의 이벤트 (Observable<Void>)
            .withLatestFrom(input.nickmaneText) /// 버튼이 눌렸을 때 가장 최신 닉네임 값을 가져옴
            .flatMapLatest { [weak self] newNickname -> Observable<Result<Void, LoginError>> in /// 닉네임이 바뀔 때마다 새로운 요청을 보내되, 이전 요청은 무시
                guard let self = self,
                      var currentUser = self.user.value else {
                    return Observable.just(.failure(.noUser))
                }
                
                currentUser.nickname = newNickname
                self.user.accept(currentUser)
                
                return self.loginUseCase.updateUser(user: currentUser)
                    .map { $0.mapToVoid() }
                    
            }
        
        let nicknameEditResult = endBtnTapped
            .asDriver(onErrorJustReturn: .failure(.noUser))
        
        
        return NicknameEditOutput(isNicknameValid: isNicknameValid,
                                  nicknameChangeResult: nicknameEditResult)
    }
}


// MARK: - FCM 토큰 생성 함수
extension LoginViewModel {
    func generateFCMToken() -> Observable<String> {
        return Observable.create { observer in
            Messaging.messaging().token { token, error in
                if let error = error {
                    print("⚠️ FCM 토큰 발급 실패: \(error.localizedDescription)")
                    print("⚠️ FCM 토큰을 받을 수 없는 기기라서 넘아갑니다.")
                    observer.onNext("noFCM")
                    observer.onCompleted()
                } else if let token = token {
                    observer.onNext(token)
                    observer.onCompleted()
                } else {
                    observer.onError(NSError(domain: "FCMToken", code: -1, userInfo: [NSLocalizedDescriptionKey: "토큰이 없습니다"]))
                }
            }
            return Disposables.create()
        }
    }
}

// MARK: - FCM 토큰 갱신 함수
extension LoginViewModel {
    
    private func updateUser(user: User) -> Observable<Result<Void, LoginError>> {
        loginUseCase
            .updateUser(user: user)
            .map { [weak self] result -> Result<Void, LoginError> in
                if case .success(let user) = result {
                    self?.user.accept(user)
                    UserDefaultsManager.shared.saveUser(user)
                }
                return result.mapToVoid()
            }
    }
    
    private func syncFCMTokenWithServerIfNeeded(currentUser: User) {
        guard let localToken = UserDefaults.standard.string(forKey: "localFCMToken") else {
            print("⚠️ 로컬에 저장된 토큰 없음")
            return
        }
        
        let serverToken = currentUser.fcmToken ?? ""
        
        if serverToken != localToken {
            print("🔄 서버와 토큰 불일치: 서버=\(currentUser.fcmToken ?? "nil") / 로컬=\(localToken) → 업데이트 시도")
            var updatedUser = currentUser
            updatedUser.fcmToken = localToken
            
            updateUser(user: updatedUser)
                .subscribe(onNext: { result in
                    switch result {
                    case .success:
                        print("✅ 서버 토큰 동기화 완료")
                    case .failure(let error):
                        print("❌ 토큰 동기화 실패: \(error)")
                    }
                })
                .disposed(by: disposeBag)
        } else {
            print("✅ 서버와 로컬 토큰 일치")
        }
    }
}

final class StubLoginViewModel: LoginViewModelType {
    
    var user = RxRelay.BehaviorRelay<User?>(value: User.empty(loginPlatform: .apple))
    
    func transform(input: LoginViewModel.LoginInput) -> LoginViewModel.LoginOutput {
        return .init(loginResult: Driver.just(.success(())))
    }
    
    func transform(input: LoginViewModel.NicknameInput) -> LoginViewModel.NicknameOutput {
        return .init(isNicknameValid: .just(true), moveToBirthday: .just(()))
    }
    
    func transform(input: LoginViewModel.BirthdayInput) -> LoginViewModel.BirthdayOutput {
        return .init(moveToProfile: .just(()))
    }
    
    func transform(input: LoginViewModel.ProfileInput) -> LoginViewModel.ProfileOutput {
        return .init(signUpResult: .just(.success(())))
    }
    
    func transform(input: LoginViewModel.NicknameEditInput) -> LoginViewModel.NicknameEditOutput {
        return .init(isNicknameValid: .just(false), nicknameChangeResult: Driver.just(.success(())))
    }
}

