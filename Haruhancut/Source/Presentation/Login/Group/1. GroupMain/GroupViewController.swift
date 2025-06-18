//  GroupViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import UIKit
import RxSwift

final class GroupViewController: UIViewController {
    weak var coordinator: HomeCoordinator?
    private let disposeBag = DisposeBag()
    private let groupViewModel: GroupViewModelType
    private let customView = GroupView()
    
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
        setNavi()
        rxBtnTap()
    }

    // MARK: - Bindings
    private func bindViewModel() {

    }
    
    private func rxBtnTap() {
        customView.enterButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.coordinator?.startGroupEnter()
            }).disposed(by: disposeBag)
        
        customView.hostButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.coordinator?.startGroupHost()
            }).disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func setNavi() {
        /// 네비게이션 타이틀 설정
        self.navigationItem.titleView = customView.titleLabel
        
        /// 커스텀 뒤로가기
        let backItem = UIBarButtonItem()
        backItem.title = "뒤로가기"
        navigationItem.backBarButtonItem = backItem
        navigationController?.navigationBar.tintColor = .mainWhite
    }
}

#Preview {
    GroupViewController(groupViewModel: StubGroupViewModel())
}
