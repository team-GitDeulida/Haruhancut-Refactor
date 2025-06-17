//
//  GroupUsecase.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import RxSwift
import UIKit

protocol GroupUsecaseProtocol {
    func createGroup(groupName: String) -> Observable<Result<(groupId: String, inviteCode: String), GroupError>>
    func updateUserGroupId(groupId: String) -> Observable<Result<Void, GroupError>>
    func fetchGroup(groupId: String) -> Observable<Result<HCGroup, GroupError>>
    func joinGroup(inviteCode: String) -> RxSwift.Observable<Result<HCGroup, GroupError>>
}

final class GroupUsecase: GroupUsecaseProtocol {
    
    private let repository: GroupRepositoryProtocol
    
    init(repository: GroupRepositoryProtocol) {
        self.repository = repository
    }
    
    func createGroup(groupName: String) -> RxSwift.Observable<Result<(groupId: String, inviteCode: String), GroupError>> {
        return repository.createGroup(groupName: groupName)
    }
    
    func updateUserGroupId(groupId: String) -> RxSwift.Observable<Result<Void, GroupError>> {
        return repository.updateUserGroupId(groupId: groupId)
    }
    
    func fetchGroup(groupId: String) -> RxSwift.Observable<Result<HCGroup, GroupError>> {
        return repository.fetchGroup(groupId: groupId)
    }
    
    func joinGroup(inviteCode: String) -> RxSwift.Observable<Result<HCGroup, GroupError>> {
        return repository.joinGroup(inviteCode: inviteCode)
    }
}

final class StubGroupUsecase: GroupUsecaseProtocol {
    func createGroup(groupName: String) -> RxSwift.Observable<Result<(groupId: String, inviteCode: String), GroupError>> {
        return .just(.success(("stub-group-id", "1234")))
    }
    
    func updateUserGroupId(groupId: String) -> RxSwift.Observable<Result<Void, GroupError>> {
        .just(.success(()))
    }
    
    func fetchGroup(groupId: String) -> RxSwift.Observable<Result<HCGroup, GroupError>> {
        return .just(.failure(.fetchGroupError))
    }
    
    func joinGroup(inviteCode: String) -> RxSwift.Observable<Result<HCGroup, GroupError>> {
        return .just(.failure(.fetchGroupError))
    }
}
