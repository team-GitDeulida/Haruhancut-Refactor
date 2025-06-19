//  ImageScrollViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/19/25.
//

import UIKit
import RxSwift

final class ImageScrollViewController: UIViewController {
    weak var coordinator: HomeCoordinator?
    private let homeViewModel: HomeViewModelType
    private let customView: ImageScrollView
    private let disposeBag = DisposeBag()
    
    // MARK: - Initializer
    init(posts: [Post],
         selectedDate: String,
         homeViewModel: HomeViewModelType
    ) {
        self.homeViewModel = homeViewModel
        self.customView = ImageScrollView(posts: posts, selectedDate: selectedDate)
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
        bindViewModel()
    }
    
    // MARK: - setDelegate
    private func setDelegate() {
        customView.collectionView.dataSource = self
        customView.collectionView.delegate = self
    }

    // MARK: - Bindings
    private func bindViewModel() {
        
        /// 그룹 갱신
        homeViewModel.group
            .compactMap { $0?.postsByDate[self.customView.selectedDate] }
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] latestPosts in
                guard let self = self else { return }
                self.customView.posts = latestPosts
                self.customView.collectionView.reloadData()
                if self.customView.posts.indices.contains(customView.currentIndex) {
                    let post = customView.posts[customView.currentIndex]
                    customView.commentButton.setCount(post.comments.count)
                }
            }).disposed(by: disposeBag)
        
        /// 닫힘 탭 이벤트
        customView.closeButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                dismiss(animated: true)
            }).disposed(by: disposeBag)
        
        /// 댓글 탭 이벤트
        customView.commentButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }

                // MARK: - 이렇게 하면 되는데
                let vc = FeedCommentViewController(homeViewModel: homeViewModel, post: customView.posts[customView.currentIndex])
                vc.modalPresentationStyle = .pageSheet
                present(vc, animated: true)
                
                // MARK: - 이렇게하면 에러발생
                /*
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.coordinator?.startComment(post: self.customView.posts[self.customView.currentIndex])
                }
                 */
            }).disposed(by: disposeBag)
    }
}

extension ImageScrollViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return customView.posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.reuseIdentifier, for: indexPath) as! ImageCell
       
        let post = customView.posts[indexPath.item]
        cell.setKFImage(url: post.imageURL)
        
        // MARK: - 이미지 콜백
        cell.onImageTap = { [weak self] image in
            guard let self = self else { return }
            guard let image = image else { return }
            let previewVC = ImagePreViewController(image: image)
            previewVC.modalPresentationStyle = .fullScreen
            self.present(previewVC, animated: true)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 40 // 좌우 20 여백
        return CGSize(width: width, height: width)
    }
    
    // 스크롤시 currentIndex 카운팅
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = customView.collectionView.frame.width
        let offsetX = customView.collectionView.contentOffset.x
        let index = Int(round(offsetX / pageWidth))
        customView.currentIndex = index

        // ⭐️ 댓글 수 즉시 반영
        /// posts 배열에 현재 curidx가 포함되어 있는가 체크 (예: 사진이 3장인데 currentIndex가 0, 1, 2 중 하나인지)
        if customView.posts.indices.contains(customView.currentIndex) {
            /// 현재 보고 있는 사진 post객체를 가져옴
            let post = customView.posts[customView.currentIndex]
            customView.commentButton.setCount(post.comments.count)
        }
    }
}

#Preview {
    ImageScrollViewController(posts: Post.samplePosts, selectedDate: "", homeViewModel: StubHomeViewModel())
}
