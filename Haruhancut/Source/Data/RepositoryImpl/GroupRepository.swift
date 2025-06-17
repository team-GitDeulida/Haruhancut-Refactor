//
//  GroupRepository.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import Foundation
import RxSwift
import FirebaseAuth
import FirebaseDatabase
import UIKit

protocol GroupRepositoryProtocol {
    func createGroup(groupName: String) -> Observable<Result<(groupId: String, inviteCode: String), GroupError>>
    func updateUserGroupId(groupId: String) -> Observable<Result<Void, GroupError>>
    func fetchGroup(groupId: String) -> Observable<Result<HCGroup, GroupError>>
    func joinGroup(inviteCode: String) -> RxSwift.Observable<Result<HCGroup, GroupError>>
}

final class GroupRepositoryProtocolImpl: GroupRepositoryProtocol {

    private let firebaseAuthManager: FirebaseAuthManagerProtocol
    
    init(firebaseAuthManager: FirebaseAuthManagerProtocol) {
        self.firebaseAuthManager = firebaseAuthManager
    }
    
    func createGroup(groupName: String) -> RxSwift.Observable<Result<(groupId: String, inviteCode: String), GroupError>> {
        return firebaseAuthManager.createGroup(groupName: groupName)
    }
    
    func updateUserGroupId(groupId: String) -> RxSwift.Observable<Result<Void, GroupError>> {
        return firebaseAuthManager.updateUserGroupId(groupId: groupId)
    }
    
    func fetchGroup(groupId: String) -> RxSwift.Observable<Result<HCGroup, GroupError>> {
        return firebaseAuthManager.fetchGroup(groupId: groupId)
    }
    
    func joinGroup(inviteCode: String) -> RxSwift.Observable<Result<HCGroup, GroupError>> {
        return firebaseAuthManager.joinGroup(inviteCode: inviteCode)
    }
}
