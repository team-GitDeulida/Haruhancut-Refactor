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
    func deletePost(_ post: Post)
    func fetchGroup(groupId: String)
    
    /// 댓글 관련
    func addComment(post: Post, text: String) -> Driver<Bool>
    func deleteComment(post: Post, commentId: String) -> Driver<Bool>
    
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
        
        /// 멤버 스냅샷
        group
            .compactMap { $0?.members.map { $0.key } }
            .distinctUntilChanged { $0 == $1 }
            .subscribe(onNext: { [weak self] memberUIDs in
                self?.observeAllMembersRealtime(memberUIDs: memberUIDs)
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
    
    // MARK: - 프로필 뷰컨에서 사용
    func fetchGroup(groupId: String) {
        self.groupUsecase.fetchGroup(groupId: groupId)
            .bind(onNext: { result in
                switch result {
                case .success(let group):
                    self.group.accept(group)
                    UserDefaultsManager.shared.saveGroup(group)
                    
                    // posts 업데이트
                    let allPosts = group.postsByDate.flatMap { $0.value }
                    let sortedPosts = allPosts.sorted(by: { $0.createdAt < $1.createdAt }) // 오래된 순
                    self.posts.accept(sortedPosts)
                    
                case .failure(let error):
                    print("❌ 그룹 가져오기 실패: \(error)")
                }
            })
            .disposed(by: disposeBag)
    }
    
    /// 그룹 스냅샷
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
    
    /// 멤버 스냅샷
    func observeAllMembersRealtime(memberUIDs: [String]) {
        /// 1) 신규 uid구독 추가
        memberUIDs.forEach { [weak self] uid in
            guard let self = self else { return }
            
            if memberSnapshotDisposables[uid] == nil {
                let disposable = self.groupUsecase.observeValueStream(path: "users/\(uid)",
                                                                      type: UserDTO.self)
                    .compactMap { $0.toModel() }
                    .subscribe(onNext: { [weak self] user in
                        guard let self = self else { return }
                        var currentMembers = self.members.value
                        if let idx = currentMembers.firstIndex(where: { $0.uid == user.uid }) {
                            currentMembers[idx] = user
                        } else {
                            currentMembers.append(user)
                        }
                        self.members.accept(currentMembers)
                        
                    }, onError: { error in
                        print("❌ 사용자 정보 없음 캐시 삭제 진행")
                        self.user.accept(nil)
                        UserDefaultsManager.shared.removeUser()
                        UserDefaultsManager.shared.removeGroup()
                        
                        // 강제 로그아웃 유도
                        NotificationCenter.default.post(name: .userForceLoggedOut, object: nil)
                    }
                    )
                memberSnapshotDisposables[uid] = disposable
            }
            
        }
        // 2. 더 이상 없는 uid 구독 해제 및 members에서 제거
        let removedUIDs = Set(memberSnapshotDisposables.keys).subtracting(memberUIDs)
        removedUIDs.forEach { uid in
            memberSnapshotDisposables[uid]?.dispose()
            memberSnapshotDisposables.removeValue(forKey: uid)
            var current = self.members.value
            current.removeAll { $0.uid == uid }
            self.members.accept(current)
        }
    }
    
    /// 그룹 사진 업로드
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
    
    /// 그룹 사진 삭제
    func deletePost(_ post: Post) {
        guard let groupId = group.value?.groupId else { return }

        let dateKey = post.createdAt.toDateKey()
        let dbPath = "groups/\(groupId)/postsByDate/\(dateKey)/\(post.postId)"
        let storagePath = "groups/\(groupId)/images/\(post.postId).jpg"
        
        /// 1. realtime Database에서 삭제
        self.groupUsecase.deleteValue(path: dbPath)
            .flatMap { success -> Observable<Bool> in
                guard success else { return .just(false) }
                
                /// 2. storage에서도 삭제
                return self.groupUsecase.deleteImage(path: storagePath)
                
            }
            .bind(onNext: { success in
                
                print("✅ 삭제 완료: \(success)")
                /// 추후 위젯 관련 기능 추가 예정
            })
            .disposed(by: disposeBag)
            
    }
}

// MARK: - 댓글 관련
extension HomeViewModel {
    
    // MARK: - 댓글 추가
    
    /// <#Description#>
    /// - Parameters:
    ///   - post: 댓글을 작성할 게시물
    ///   - text: 댓글 텍스트
    /// - Returns: 처리 성공 여부
    func addComment(post: Post, text: String) -> Driver<Bool> {
        // 유저 정보 없으면 리턴
        guard let user = user.value else { return .just(false) }
        guard let groupId = group.value?.groupId else { return .just(false) }
        
        let commentId = UUID().uuidString
        let newComment = Comment(
            commentId: commentId,
            userId: user.uid,
            nickname: user.nickname,
            profileImageURL: user.profileImageURL,
            text: text,
            createdAt: Date()
        )
        
        // 경로: groups/{groupId}/postsByDate/{날짜}/{postId}/comments/{commentId}
        let dateKey = post.createdAt.toDateKey()
        let path = "groups/\(groupId)/postsByDate/\(dateKey)/\(post.postId)/comments/\(commentId)"
        let commentDTO = newComment.toDTO()
        
        return self.groupUsecase.addComment(path: path, value: commentDTO)
            .asDriver(onErrorJustReturn: false)
    }
    
    
    /// 댓글 삭제
    /// - Parameters:
    ///   - post: 댓글이 포함된 게시물
    ///   - commentId: 삭제할 댓글 Id
    /// - Returns: 처리 성공 여부
    func deleteComment(post: Post, commentId: String) -> Driver<Bool> {
        guard let groupId = group.value?.groupId else { return .just(false) }
        
        // 게시글 작성된 날짜를 키로 변환 (예: "2025-05-20")
        let dateKey = post.createdAt.toDateKey()
        
        // 삭제할 댓글의 경로 구성
        let path = "groups/\(groupId)/postsByDate/\(dateKey)/\(post.postId)/comments/\(commentId)"
        
        return self.groupUsecase.deleteComment(path: path)
            .asDriver(onErrorJustReturn: false)
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
    func deletePost(_ post: Post) {}
    func addComment(post: Post, text: String) -> Driver<Bool> {
        return .just(false)
    }
    func deleteComment(post: Post, commentId: String) -> Driver<Bool> {
        return .just(false)
    }
    func fetchGroup(groupId: String) {}
}
