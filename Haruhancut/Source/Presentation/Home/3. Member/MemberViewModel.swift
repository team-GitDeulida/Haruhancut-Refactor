//  MemberViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 6/19/25.
//

import UIKit
import RxSwift
import RxCocoa

protocol MemberViewModelType {
    var membersRelay: BehaviorRelay<[User]> { get }
    var members: Driver<[User]> { get }
}

final class MemberViewModel: MemberViewModelType {
    private let loginUsecase: LoginUsecaseProtocol
    
    var membersRelay: BehaviorRelay<[User]>
    var members: Driver<[User]> { membersRelay.asDriver() }
    
    init(loginUsecase: LoginUsecaseProtocol,
         membersRelay: BehaviorRelay<[User]>
    ) {
        self.loginUsecase = loginUsecase
        self.membersRelay = membersRelay
    }
}

final class StubMemberViewModel: MemberViewModelType {
    var membersRelay = BehaviorRelay<[User]>(value: [
        User.sampleUser1,
        User.sampleUser2
    ])
    var members: Driver<[User]> { membersRelay.asDriver() }
}
