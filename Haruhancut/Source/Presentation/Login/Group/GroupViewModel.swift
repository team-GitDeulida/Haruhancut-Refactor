//  GroupViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import UIKit
import RxSwift
import RxCocoa

protocol GroupViewModelType {
    func transform(input: GroupViewModel.GroupHostInput) -> GroupViewModel.GroupHostOutput
}

final class GroupViewModel: GroupViewModelType {
    private let loginViewModel: LoginViewModel
    private let homeViewModel: HomeViewModel
    private let groupUsecase: GroupUsecaseProtocol
    var groupName = BehaviorRelay<String>(value: "")
    
    init(loginViewModel: LoginViewModel,
         homeViewModel: HomeViewModel,
         groupUsecase: GroupUsecaseProtocol
    ) {
        self.loginViewModel = loginViewModel
        self.homeViewModel = homeViewModel
        self.groupUsecase = groupUsecase
    }
}

extension GroupViewModel {
    struct GroupHostInput {
        let groupNameText: Observable<String>
        let endBtnTapped: Observable<Void>
    }
    
    struct GroupHostOutput {
        let hostResult: Driver<Result<String, GroupError>>
        let isGroupNameValid: Driver<Bool>
    }
    
    func transform(input: GroupHostInput) -> GroupHostOutput {
        let hostResult = input.endBtnTapped
            .withLatestFrom(input.groupNameText)
            .flatMapLatest { [weak self] groupName -> Observable<Result<String, GroupError>> in
                guard let self = self else {
                    return .just(.failure(.makeHostError))
                }
                self.groupName.accept(groupName)
                
                // 1. 그룹 만들기
                return self.groupUsecase.createGroup(groupName: groupName)
                    .flatMapLatest { result -> Observable<Result<String, GroupError>> in
                        switch result {
                        case .success(let groupInfo):
                            let groupId = groupInfo.groupId
                            let inviteCode = groupInfo.inviteCode
                            
                            // 2. 그룹만들기 성공 -> 유저업데이트 시도
                            return self.groupUsecase.updateUserGroupId(groupId: groupId)
                                .map { updatedResult in
                                    switch updatedResult {
                                    case .success:
                                        // 3. 그룹 생성 성공 -> loginVM 메모리의 user.groupId도 업데이트
                                        if var currentUser = self.loginViewModel.user.value {
                                            currentUser.groupId = groupId
                                            self.loginViewModel.user.accept(currentUser)
                                            UserDefaultsManager.shared.saveUser(currentUser)
                                            
                                            // 4. loginVM의 groupRelay도 갱신
                                            let group = HCGroup(groupId: groupId,
                                                                groupName: groupName,
                                                                createdAt: Date(),
                                                                hostUserId: currentUser.uid,
                                                                inviteCode: inviteCode,
                                                                members: [:],
                                                                postsByDate: [:])
                                            self.homeViewModel.group.accept(group)
                                            UserDefaultsManager.shared.saveGroup(group)
                                        }
                                        return .success(groupId)
                                    case .failure:
                                        return .failure(.makeHostError)
                                    }
                                }
                        case .failure:
                            /// 그룹만들기 실패
                            return .just(.failure(.makeHostError))
                        }
                    }
            }.asDriver(onErrorJustReturn: .failure(.makeHostError))
        
        let isGroupNameVailed = input.groupNameText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 }
            .distinctUntilChanged() // 중복된 값은 무시하고 변경될 때만 아래로 전달
            .asDriver(onErrorJustReturn: false) // 에러 발생 시에도 false를 대신 방출
        
        return GroupHostOutput(hostResult: hostResult,
                               isGroupNameValid: isGroupNameVailed)
    }
}

final class StubGroupViewModel: GroupViewModelType {
    func transform(input: GroupViewModel.GroupHostInput) -> GroupViewModel.GroupHostOutput {
        return .init(hostResult: Driver.just(.success("stub-group-Id")),
                     isGroupNameValid: Driver.just(true))
    }
}
