//  FeedDetailViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/19/25.
//

import UIKit

final class FeedDetailViewController: UIViewController {
    weak var coordinator: HomeCoordinator?
    private let homeViewModel: HomeViewModelType
    private let customView: FeedDetailView
    
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
