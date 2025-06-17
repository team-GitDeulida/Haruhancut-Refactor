//  HomeViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import UIKit

final class HomeViewController: UIViewController {
    weak var coordinator: HomeCoordinator?
    private let viewModel: HomeViewModelType
    private let customView = HomeView()
    
    // MARK: - Initializer
    init(viewModel: HomeViewModelType) {
        self.viewModel = viewModel
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
    }

    // MARK: - Bindings
    private func bindViewModel() {

    }
}

#Preview {
    HomeViewController(viewModel: StubHomeViewModel())
}
