//  CalendarViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import UIKit

final class CalendarViewController: UIViewController {
    weak var coordinator: HomeCoordinator?
    private let homeViewModel: HomeViewModelType
    private let customView = CalendarView()
    
    // MARK: - Initializer
    init(homeViewModel: HomeViewModelType) {
        self.homeViewModel = homeViewModel
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
    CalendarViewController(homeViewModel: StubHomeViewModel())
}
