//  GroupEnterViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import UIKit
import RxSwift

final class GroupEnterViewController: UIViewController {
    weak var coordinator: HomeCoordinator?
    private let groupViewModel: GroupViewModelType
    private let customView = GroupEnterView()
    private let disposeBag = DisposeBag()
    
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
        bindViewModel()
    }
    
    // 외부 터치 시 키보드 내리기
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }

    // MARK: - Bindings
    private func bindViewModel() {
        /// return키 입력시 키보드 내려감
        customView.textField.rx.controlEvent(.editingDidEndOnExit)
            .bind(onNext: { [weak self] in
                guard let self = self else { return }
                self.view.endEditing(true)
            }).disposed(by: disposeBag)
        
        let input = GroupViewModel.GroupEnterInput(inviteCodeText: customView.textField.rx.text.orEmpty.asObservable(),
                                                   endBtnTapped: customView.endButton.rx.tap.asObservable())
        let output = groupViewModel.transform(input: input)
        
        /// 그룹 만들기
        /// 성공 - 홈으로 이동
        /// 실패 - 에러 알람
        output.enterResult
            .drive(onNext: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.coordinator?.startHome()
                case .failure(let error):
                    AlertManager.showError(on: self, message: "초대 코드가 유효하지 않습니다: \n\(error.localizedDescription)")
                }
            }).disposed(by: disposeBag)
        
        /// 초대코드 비어있으면 버튼 비활성화
        output.inInviteCodeValid
            .drive(onNext: { [weak self] isVaild in
                guard let self = self else { return }
                self.customView.endButton.isEnabled = isVaild
                self.customView.endButton.alpha = isVaild ? 1 : 0.5
            }).disposed(by: disposeBag)
        
    }
}

#Preview {
    GroupEnterViewController(groupViewModel: StubGroupViewModel())
}
