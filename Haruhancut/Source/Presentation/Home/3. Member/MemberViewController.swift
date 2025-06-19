//  MemberViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/19/25.
//

import UIKit
import RxSwift

final class MemberViewController: UIViewController {
    weak var coordinator: HomeCoordinator?
    private let memberviewModel: MemberViewModelType
    private let homeViewModel: HomeViewModelType
    private let customView = MemberView()
    private let disposeBag = DisposeBag()
    
    // MARK: - Initializer
    init(memberviewModel: MemberViewModelType,
         homeViewModel: HomeViewModelType
    ) {
        self.memberviewModel = memberviewModel
        self.homeViewModel = homeViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - LifeCycle
    override func loadView() {
        self.view = customView
        navigationItem.titleView = customView.titleLabel
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }

    // MARK: - Bindings
    private func bindViewModel() {
        memberviewModel.members
            .drive(onNext: { [weak self] members in
                guard let self = self else { return }
                
                // 1) 멤버 수 업데이트
                self.customView.peopleLabel.text = "\(members.count)명"
                
                // 2) 기존 서브뷰 제거
                self.customView.memberStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                
                // 3) 최상단에 초대용 버튼 추가
                let addView = AddMemberCircleView()
                addView.heightAnchor.constraint(equalToConstant: 60).isActive = true
                addView.onTap = { [weak self] in
                    guard let self = self else { return }
                    
                    let inviteCode = self.homeViewModel.group.value!.inviteCode
                    self.shareInvitation(inviteCode: inviteCode)
                }
                self.customView.memberStackView.addArrangedSubview(addView)
                
                // 4) 실제 멤버들은 정렬 후 추가
                let sorted = members.sorted { lhs, rhs in
                    if lhs.uid == self.homeViewModel.user.value?.uid { return true }
                    if rhs.uid == self.homeViewModel.user.value?.uid { return false }
                    return lhs.registerDate < rhs.registerDate
                }
                
                sorted.forEach { user in
                    let url = user.profileImageURL.flatMap(URL.init(string:))
                    let circle = FamilyMemberCircleView(name: user.nickname, imageURL: url)
                    circle.heightAnchor.constraint(equalToConstant: 60).isActive = true
                    circle.onProfileTapped = { [weak self] in
                        guard let self = self, let img = circle.image else { return }
                        let vc = ImagePreViewController(image: img)
                        vc.modalPresentationStyle = .fullScreen
                        self.present(vc, animated: true)
                    }
                    self.customView.memberStackView.addArrangedSubview(circle)
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - 초대 함수
    private func shareInvitation(inviteCode: String) {
        // 1) 초대 메시지
        let inviteURL = "https://www.notion.so/210db9e736cf80d4b3a8c7e077e6325f?source=copy_link"
        let message = """
우리 가족 그룹에 초대할게요!
초대코드: \(inviteCode)

앱이 궁금하다면 👉 
\(inviteURL)

앱 설치하기 🍎
\(Constants.Appstore.appstoreURL)
"""
        // 2) UIActivityViewController 생성
        let items: [Any] = [message]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // 3) iPad 대응(팝오버 위치)
        if let pop = activityVC.popoverPresentationController {
            pop.sourceView = self.view
            pop.sourceRect = CGRect(x: view.bounds.midX,
                                    y: view.bounds.midY,
                                    width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        
        // 4) 공유 시트 표시
        present(activityVC, animated: true)
    }
}

#Preview {
    MemberViewController(memberviewModel: StubMemberViewModel(),
                         homeViewModel: StubHomeViewModel())
}
