//  FeedCommentViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/19/25.
//

import UIKit
import RxSwift

final class FeedCommentViewController: UIViewController {
 
    private let homeViewModel: HomeViewModelType
    private let customView: FeedCommentView
    private var comments: [(commentId: String, comment: Comment)] = []
    private let disposeBag = DisposeBag()
    
    // MARK: - Initializer
    init(homeViewModel: HomeViewModelType,
         post: Post
    ) {
        self.homeViewModel = homeViewModel
        self.customView = FeedCommentView(post: post)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - LifeCycle
    override func loadView() {
        self.view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegate()
        addTarget()
        bindViewModel()
    }
    
    // MARK: - 모달
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /// pageSheet일때만
        if let sheet = self.sheetPresentationController {
            if #available(iOS 16.0, *) {
                let fiftyPercentDetent = UISheetPresentationController.Detent.custom(identifier: .init("fiftyPercent")) { context in
                                return context.maximumDetentValue * 0.6
                            }

                let eightyPercentDetent = UISheetPresentationController.Detent.custom(identifier: .init("eightyPercent")) { context in
                    return context.maximumDetentValue * 0.9
                }
                
                sheet.detents = [fiftyPercentDetent, eightyPercentDetent]
            } else {
                sheet.detents = [.medium(), .large()]
            }
            /// 바텀시트 상단에 손잡이(Grabber) 표시 여부
            sheet.prefersGrabberVisible = true
            /// 시트의 상단 모서리를 30pt 둥글게
            sheet.preferredCornerRadius = 30
        }
        
        modalPresentationStyle = .pageSheet
    }
    
    // MARK: - delegate
    private func setDelegate() {
        customView.tableView.dataSource = self
        customView.tableView.delegate = self
    }
    
    // MARK: - addTarget
    private func addTarget() {
        customView.chattingView.sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
    }

    // MARK: - Bindings
    private func bindViewModel() {
        homeViewModel
            .posts
            .asDriver()
            .drive(onNext: { [weak self] posts in
                guard let self = self else { return }
                guard let latestPost = posts.first(where: { $0.postId == self.customView.post.postId }) else { return }
                
                /// 댓글 최신순 정렬
                let sorted = latestPost.comments
                    .sorted { $0.value.createdAt < $1.value.createdAt }
                    .map { (commentId, comment) -> (String, Comment) in
                        var updatedComment = comment
                        
                        /// 모든 댓글에 대해 userId로 members에사 사용자 찾기
                        if let user = self.homeViewModel.members.value.first(where: { $0.uid == comment.userId }) {
                            updatedComment.profileImageURL = user.profileImageURL
                        }
                        return (commentId: commentId, comment: updatedComment)
                    }
                
                self.comments = sorted // [(key, Comment)]
                self.customView.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Tap
    @objc private func sendButtonTapped() {
        let text = customView.chattingView.text
        guard !text.isEmpty else { return }
        
        homeViewModel.addComment(post: customView.post, text: text)
            .drive(onNext: { [weak self] success in
                guard let self = self else { return }
                if success {
                    // 입력창 초기화
                    customView.chattingView.clearInput()
                } else {
                    AlertManager.showError(on: self, message: "댓글 작성 실패하였습니다.")
                }
                
            }).disposed(by: disposeBag)
        
    }
}

extension FeedCommentViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentCell.reuseIdentifier, for: indexPath) as? CommentCell else {
            return UITableViewCell()
        }
        
        let comment = comments[indexPath.row].comment
        cell.configure(comment: comment)
        
        // 선택 효과 제거(터치는 가능하지만 시각적 변화 X)
        cell.selectionStyle = .none
        return cell
    }
    
}

extension FeedCommentViewController: UITableViewDelegate {
    // 스와이프 액션 처리
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let comment = comments[indexPath.row]
        
        // 본인 댓글이 아닐 경우 삭제 금지
        guard comment.comment.userId == homeViewModel.user.value?.uid else {
            return nil
        }
        
        // 삭제 액션 정의
        let deleteAction = UIContextualAction(style: .destructive, title: "삭제") { [weak self] (_, _, completionHandler) in
            guard let self = self else { return }
            
            // ViewModel 통해 댓글 삭제 요청
             self.homeViewModel.deleteComment(post: self.customView.post, commentId: comment.comment.commentId)
                .drive(onNext: { [weak self] success in
                    guard let self = self else { return }
                    
                    if success {
                        completionHandler(true)
                    } else {
                        AlertManager.showError(on: self, message: "삭제 실패하였습니다.")
                        completionHandler(false)
                    }
                }).disposed(by: disposeBag)
        }

        let config = UISwipeActionsConfiguration(actions: [deleteAction])
        config.performsFirstActionWithFullSwipe = true // 풀 스와이프 허용 여부
        return config
    }
}

#Preview {
    FeedCommentViewController(homeViewModel: StubHomeViewModel(),
                              post: Post.samplePosts[0])
}
