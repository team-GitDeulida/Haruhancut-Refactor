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
    func joinGroup(inviteCode: String) -> RxSwift.Observable<Result<HCGroup, GroupError>>
    func updateUserGroupId(groupId: String) -> Observable<Result<Void, GroupError>>
    func updateGroup(path: String, post: PostDTO) -> Observable<Bool>
    func fetchGroup(groupId: String) -> Observable<Result<HCGroup, GroupError>>
    func uploadImage(image: UIImage, path: String) -> Observable<URL?>
    func deleteImage(path: String) -> Observable<Bool>
    func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<T>
    func deleteValue(path: String) -> Observable<Bool>
}

final class GroupRepository: GroupRepositoryProtocol {

    private let firebaseAuthManager: FirebaseAuthManagerProtocol
    private let firebaseStorageManager: FirebaseStorageManagerProtocol
    
    init(firebaseAuthManager: FirebaseAuthManagerProtocol, firebaseStorageManager: FirebaseStorageManagerProtocol
    ) {
        self.firebaseAuthManager = firebaseAuthManager
        self.firebaseStorageManager = firebaseStorageManager
    }
    
    func createGroup(groupName: String) -> RxSwift.Observable<Result<(groupId: String, inviteCode: String), GroupError>> {
        return firebaseAuthManager.createGroup(groupName: groupName)
    }
    
    func joinGroup(inviteCode: String) -> RxSwift.Observable<Result<HCGroup, GroupError>> {
        return firebaseAuthManager.joinGroup(inviteCode: inviteCode)
    }
    
    func updateGroup(path: String, post: PostDTO) -> Observable<Bool> {
        return firebaseAuthManager.updateGroup(path: path, post: post)
    }
    
    func updateUserGroupId(groupId: String) -> RxSwift.Observable<Result<Void, GroupError>> {
        return firebaseAuthManager.updateUserGroupId(groupId: groupId)
    }
    
    func fetchGroup(groupId: String) -> RxSwift.Observable<Result<HCGroup, GroupError>> {
        return firebaseAuthManager.fetchGroup(groupId: groupId)
    }
    
    func uploadImage(image: UIImage, path: String) -> Observable<URL?> {
        return firebaseStorageManager.uploadImage(image: image, path: path)
    }
    
    func deleteImage(path: String) -> Observable<Bool> {
        return firebaseStorageManager.deleteImage(path: path)
    }
    
    func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<T> {
        return firebaseAuthManager.observeValueStream(path: path, type: type)
    }
    
    func deleteValue(path: String) -> Observable<Bool> {
        return firebaseAuthManager.deleteValue(path: path)
    }
}
