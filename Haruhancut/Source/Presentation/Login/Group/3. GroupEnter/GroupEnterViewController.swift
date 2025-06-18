//  GroupEnterViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import UIKit

final class GroupEnterViewController: UIViewController {
    private let groupViewModel: GroupViewModelType
    private let customView = GroupEnterView()
    
    // MARK: - Initializer
    init(groupViewModel: GroupViewModelType) {
        self.groupViewModel = groupViewModel
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
    GroupEnterViewController(groupViewModel: StubGroupViewModel())
}
