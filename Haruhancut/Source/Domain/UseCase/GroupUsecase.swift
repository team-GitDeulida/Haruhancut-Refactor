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
    func joinGroup(inviteCode: String) -> RxSwift.Observable<Result<HCGroup, GroupError>>
    func updateUserGroupId(groupId: String) -> Observable<Result<Void, GroupError>>
    func updateGroup(path: String, post: PostDTO) -> Observable<Bool>
    func fetchGroup(groupId: String) -> Observable<Result<HCGroup, GroupError>>
    func uploadImage(image: UIImage, path: String) -> Observable<URL?>
    func deleteImage(path: String) -> Observable<Bool>
    func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<T>
    func deleteValue(path: String) -> Observable<Bool>
    
    func addComment(path: String, value: CommentDTO) -> Observable<Bool>
    func deleteComment(path: String) -> Observable<Bool>
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
    
    func uploadImage(image: UIImage, path: String) -> Observable<URL?> {
        return repository.uploadImage(image: image, path: path)
    }
    
    func updateGroup(path: String, post: PostDTO) -> Observable<Bool> {
        return repository.updateGroup(path: path, post: post)
    }
    
    func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<T> {
        return repository.observeValueStream(path: path, type: type)
    }
    
    func deleteImage(path: String) -> Observable<Bool> {
        return repository.deleteImage(path: path)
    }
    
    func deleteValue(path: String) -> Observable<Bool> {
        return repository.deleteValue(path: path)
    }
    
    func addComment(path: String, value: CommentDTO) -> Observable<Bool> {
        return repository.addComment(path: path, value: value)
    }
    
    func deleteComment(path: String) -> Observable<Bool> {
        return repository.deleteComment(path: path)
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
    
    func uploadImage(image: UIImage, path: String) -> Observable<URL?> {
        return .just(nil)
    }
    
    func updateGroup(path: String, post: PostDTO) -> Observable<Bool> {
        return .just(false)
    }
    
    func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<T> {
        let dummyJSON = "{}".data(using: .utf8)!
        
        do {
            let value = try JSONDecoder().decode(T.self, from: dummyJSON)
            return .just(value)
        } catch {
            fatalError("❌ StubGroupUsecase: \(T.self) 디코딩 실패. 실제 타입을 확인하세요.")
        }
    }
    
    func deleteImage(path: String) -> Observable<Bool> {
        return .just(false)
    }
    
    func deleteValue(path: String) -> Observable<Bool> {
        return .just(false)
    }
    
    func addComment(path: String, value: CommentDTO) -> Observable<Bool> {
        return .just(false)
    }
    
    func deleteComment(path: String) -> Observable<Bool> {
        return .just(false)
    }
}

