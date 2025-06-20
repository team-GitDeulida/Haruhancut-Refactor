//  SettingViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 6/20/25.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseAuth

protocol SettingViewModelType {
    var user: User { get }
    func transform(input: SettingViewModel.Input) -> SettingViewModel.Output
    func alertOn()
    func alertOff()
    func deleteUser(uid: String) -> Driver<Bool>
}

final class SettingViewModel: SettingViewModelType {
    var user: User
    private let loginUseCase: LoginUsecaseProtocol
    private let disposeBag = DisposeBag()
    
    
    init(user: User, loginUseCase: LoginUsecaseProtocol) {
        self.user = user
        self.loginUseCase = loginUseCase
    }
}

extension SettingViewModel {
    struct Input {
        /// 로그아웃 버튼 이벤트
        let logoutTapped: Observable<Void>
        
        /// 토글 스위치 이벤트
        let notificationToggleTapped: Observable<Bool>
        
        /// 셀 이벤트
        let cellTapped: Observable<IndexPath>
    }
    
    struct Output {
        /// 로그아웃 성공유무 결과스트림
        let logoutResult: Driver<Result<Void, LoginError>>
        
        /// 토글 처리 결과
        let notificationResult: Driver<Bool>
        
        /// 셀 선택 통보
        let selectionResult: Driver<IndexPath>
    }
    
    func transform(input: Input) -> Output {
        
        // MARK: - 로그아웃
        let logoutResult = input.logoutTapped
            .map { _ -> Result<Void, LoginError> in
                do {
                    try Auth.auth().signOut()
                    UserDefaultsManager.shared.removeUser()
                    UserDefaultsManager.shared.removeGroup()
                    return .success(())
                } catch {
                    return .failure(.logoutError)
                }
            }.asDriver(onErrorJustReturn: .failure(.logoutError))
        
        // MARK: - 알림 토글
        let notificationResult = input.notificationToggleTapped
            .do(onNext: { isOn in
                // guard let self = self else { return }
                // isOn ? self.alertOn() : self.alertOff()
            })
            .asDriver(onErrorJustReturn: false)
        
        // MARK: - 셀 선택
        let selectionResult = input.cellTapped
            .asDriver(onErrorJustReturn: .init(row: 0, section: 0))
        
        return Output(logoutResult: logoutResult,
                      notificationResult: notificationResult,
                      selectionResult: selectionResult)
    }
        
}

extension SettingViewModel {
    func alertOn() {
        var updatedUser = self.user
        updatedUser.isPushEnabled = true
        self.updateUser(user: updatedUser)
        UserDefaultsManager.shared.setNotificationEnabled(enabled: true)
    }
    
    func alertOff() {
        var updatedUser = self.user
        updatedUser.isPushEnabled = false
        self.updateUser(user: updatedUser)
        UserDefaultsManager.shared.setNotificationEnabled(enabled: false)
    }
    
    func updateUser(user: User) {
        self.loginUseCase.updateUser(user: user)
            .subscribe(onNext: { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let user):
                    self.user = user
                    UserDefaultsManager.shared.saveUser(user)
                case .failure(let error):
                    print("유저 업데이트 실패:", error)
                }
            }).disposed(by: disposeBag)
    }
    
    func deleteUser(uid: String) -> Driver<Bool> {
        self.loginUseCase.deleteUser(uid: uid)
            .asDriver(onErrorJustReturn: false)
    }
}

final class StubSettingViewModel: SettingViewModelType {
    
    
    
    var user: User = User.sampleUser1
    func transform(input: SettingViewModel.Input) -> SettingViewModel.Output {
        return .init(logoutResult: Driver.just(.success(())),
                     notificationResult: Driver.just(true),
                     selectionResult: Driver.just(.init(row: 0, section: 0)))
    }
    func alertOn() {}
    func alertOff() {}
    func deleteUser(uid: String) -> RxCocoa.Driver<Bool> {
        return Driver.just(false)
    }
}

