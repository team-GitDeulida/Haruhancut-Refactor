//  HomeViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import UIKit
import RxSwift
import RxCocoa

enum CameraType {
    case camera
    case gallary
}

protocol HomeViewModelType {
    var posts: BehaviorRelay<[Post]> { get }
    var user: BehaviorRelay<User?> { get }
    var group: BehaviorRelay<HCGroup?> { get }
    var members: BehaviorRelay<[User]> { get }
    var cameraType: CameraType { get }
    var didUserPostToday: Observable<Bool> { get }
    func uploadPost(image: UIImage) -> Driver<Bool>
    func transform() -> HomeViewModel.Output
}

final class HomeViewModel: HomeViewModelType {
    
    // 스냅샷 구독
    private var groupSnapshotDisposable: Disposable?
    private var userSnapshotDisposable: Disposable?
    private var memberSnapshotDisposables: [String: Disposable] = [:]

    let user = BehaviorRelay<User?>(value: nil)
    let group = BehaviorRelay<HCGroup?>(value: nil)
    let posts = BehaviorRelay<[Post]>(value: [])
    let members = BehaviorRelay<[User]>(value: [])
    var didUserPostToday: Observable<Bool> {
        return Observable.combineLatest(user, posts)
            .map { user ,posts in
                guard let uid = user?.uid else { return false }
                return posts.contains { $0.isToday && $0.userId == uid }
        }
    }
    
    private let loginUsecase: LoginUsecaseProtocol
    private let groupUsecase: GroupUsecaseProtocol
    private let disposeBag = DisposeBag()
    var cameraType: CameraType
    
    init(loginUsecase: LoginUsecaseProtocol,
         groupUsecase: GroupUsecaseProtocol,
         userRelay: BehaviorRelay<User?>,
         cameraType: CameraType = .camera
    ) {
        self.loginUsecase = loginUsecase
        self.groupUsecase = groupUsecase
        self.cameraType = cameraType
        
        fetchDefaultGroup()
        
        /// loginVM의 유저 (스냅샷과 유사)
        /// homeVM이 유저 상태를 실시간 반영받도록 loginVM.userRelay를 직접 참조
        /// loginVM.userRelay에 변화가 생기면, HomeViewModel.user에게 그 값을 자동으로 전달
        userRelay
            .bind(to: user)
            .disposed(by: disposeBag)
        
        /// 그룹 스냅샷
        user
            .compactMap { $0?.groupId }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] groupId in
                guard let self = self else { return }
                self.observeGroupRealtime(groupId: groupId)
            })
            .disposed(by: disposeBag)
    }
    
    /// 캐시에서 그룹 불러오기(사용자 경험 향상)
    private func fetchDefaultGroup() {
        if let cachedGroup = UserDefaultsManager.shared.loadGroup() {
            self.group.accept(cachedGroup)
            
            // posts 업데이트
            let allPosts = cachedGroup.postsByDate.flatMap { $0.value }
            let sortedPosts = allPosts.sorted(by: { $0.createdAt < $1.createdAt }) // 오래된 순
            self.posts.accept(sortedPosts)
        } else {
            print("❌ 캐시된 그룹 없음 --- ")
        }
    }
    
    func uploadPost(image: UIImage) -> Driver<Bool> {
        if cameraType == .camera {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
        
        guard let user = user.value,
              let groupId = group.value?.groupId else {
            print("❌ 유저 또는 그룹 정보 없음")
            return .just(false).asDriver(onErrorJustReturn: false)
        }
        
        let postId = UUID().uuidString
        let dateKey = Date().toDateKey()
        let storagePath = "groups/\(groupId)/images/\(postId).jpg"         // storage  저장 위치
        let dbPath = "groups/\(groupId)/postsByDate/\(dateKey)/\(postId)"  // realtime 저장 위치
        
        return self.groupUsecase.uploadImage(image: image, path: storagePath)
            .flatMap { url -> Observable<Bool> in
                guard let imageURL = url else {
                    print("❌ URL 없음")
                    return .just(false)
                }
                
                let post = Post(postId: postId,
                                userId: user.uid,
                                nickname: user.nickname,
                                profileImageURL: user.profileImageURL,
                                imageURL: imageURL.absoluteString,
                                createdAt: Date(),
                                likeCount: 0,
                                comments: [:])
                
                return self.groupUsecase.updateGroup(path: dbPath, post: post.toDTO())
//                    .do { success in
//                        if success {
//                            // TODO: -
//                        }
//                    }
            }
            .asDriver(onErrorJustReturn: false)
    }
    
    private func observeGroupRealtime(groupId: String) {
        let path = "groups/\(groupId)"
        
        /// 1. 기존 스냅샷 제거
        groupSnapshotDisposable?.dispose()
        
        /// 2. 스냅샷 시작
        groupSnapshotDisposable = self.groupUsecase.observeValueStream(path: path,
                                                                       type: HCGroupDTO.self)
        .compactMap { $0.toModel() }
        .subscribe(onNext: { [weak self] group in
            guard let self = self else { return }
            self.group.accept(group)
            
            /// 캐시 저장
            UserDefaultsManager.shared.saveGroup(group)
            
            /// 3. posts를 날짜별로 정렬하여 포스트 변수에 바인딩
            let allPosts = group.postsByDate
                .flatMap { $0.value }
                .sorted(by: { $0.createdAt < $1.createdAt })
            
            self.posts.accept(allPosts)
            
            /// 4. 최신 포스트 체크후 위젯 컨테이너에 없으면 저장한다
            // TODO: -
        })
        
    }
    
    
}

extension HomeViewModel {
    struct Output {
        let todayPosts: Driver<[Post]>
        let groupName: Driver<String>
        let allPostsByDate: Driver<[String: [Post]]>
    }
    
    func transform() -> Output {
        // 1) 오늘 것만
        let todayPosts = posts
            .map { $0.filter { $0.isToday } }
            .asDriver(onErrorJustReturn: [])
        
        // 2) 그룹 이름
        let groupName = group
            .map { $0?.groupName ?? "그룹 없음" }
            .asDriver(onErrorJustReturn: "그룹 없음")
        
        // 3) 전체 포스트 맵(날짜 → [Post])
        let allPostsByDate = group
            .map { $0?.postsByDate ?? [:] }
            .asDriver(onErrorJustReturn: [:])
        
        return Output(todayPosts: todayPosts, groupName: groupName, allPostsByDate: allPostsByDate)
    }
}

final class StubHomeViewModel: HomeViewModelType {
    let user = BehaviorRelay<User?>(value: nil)
    let group = BehaviorRelay<HCGroup?>(value: nil)
    let posts = BehaviorRelay<[Post]>(value: [])
    let members = BehaviorRelay<[User]>(value: [])
    var cameraType: CameraType = .camera
    var didUserPostToday: Observable<Bool> = .just(false)
    func uploadPost(image: UIImage) -> Driver<Bool> {
        return .just(true)
    }
    func transform() -> HomeViewModel.Output {
        return .init(todayPosts: Driver.just([]),
                     groupName: Driver.just("stub-group-name"),
                     allPostsByDate: Driver.just([:]))
    }
    
}
