//  FeedDetailViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/19/25.
//

import UIKit
import RxSwift

final class FeedDetailViewController: UIViewController {
    weak var coordinator: HomeCoordinator?
    private let homeViewModel: HomeViewModelType
    private let customView: FeedDetailView
    private let disposeBag = DisposeBag()
    
    // MARK: - Initializer
    init(homeViewModel: HomeViewModelType,
         post: Post
    ) {
        self.homeViewModel = homeViewModel
        self.customView = FeedDetailView(post: post)
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
        addTarget()
        bindViewModel()
    }
    
    // MARK: - addTarget
    private func addTarget() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapImage))
        customView.imageView.addGestureRecognizer(tapGesture)
    }

    // MARK: - Bindings
    private func bindViewModel() {
        
        /// 버튼을 누르면 네비게이션 present 화면을 띄운다
        customView.commentButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.coordinator?.startComment(post: customView.post)
            }).disposed(by: disposeBag)
        
        
        /// 게시물 업데이트 감지 후 댓글 수 반영을 한다
        homeViewModel.posts
            // 1. viewModel의 posts중 post와 동일한 postId를 가진 게시물 찾기
            .compactMap { posts in
                posts.first(where: { $0.postId == self.customView.post.postId })
            }
            // 2. 댓글 수 변경시만 downstream으로 이벤트 방출
            .distinctUntilChanged({ $0.comments.count == $1.comments.count })
            // 3. UI 업데이트이므로 Driver로 변환(메인스레드 보장)
            .asDriver(onErrorDriveWith: .empty())
            // 4. 최신 post로 갱신 및 UI 업데이트
            .drive(onNext: { [weak self] updatedPost in
                guard let self = self else { return }
                self.customView.post = updatedPost
                self.customView.configure(post: updatedPost)
                self.customView.commentButton.setCount(updatedPost.comments.count)
            }).disposed(by: disposeBag)
    }
}

extension FeedDetailViewController {
    
    /// 미리보기 띄우기
    @objc private func didTapImage() {
        let previewVC = ImagePreViewController(image: customView.imageView.image!)
        previewVC.modalPresentationStyle = .fullScreen
        self.present(previewVC, animated: true)
    }
}

#Preview {
    FeedDetailViewController(homeViewModel: StubHomeViewModel(), post: Post.samplePosts[0])
}
