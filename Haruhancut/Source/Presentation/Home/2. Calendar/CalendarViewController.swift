//  CalendarViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import UIKit
import FSCalendar
import RxSwift

final class CalendarViewController: UIViewController {
    weak var coordinator: HomeCoordinator?
    private let homeViewModel: HomeViewModelType
    private let customView = CalendarView()
    private let disposeBag = DisposeBag()
    
    // MARK: - Callback
    var onPresent: ((UIViewController) -> Void)?
    
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
        setDelegate()
        bindViewModel()
    }
    
    // MARK: - setDelegate()
    private func setDelegate() {
        // 프로토콜 연결
        customView.calendarView.dataSource = self
        customView.calendarView.delegate = self
    }

    // MARK: - Bindings
    private func bindViewModel() {
        /// 새로운 그룹 정보를 방출할 때 마다 캘린더 새로고침
        homeViewModel.group
            .asDriver()
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.customView.calendarView.reloadData()
            }).disposed(by: disposeBag)
            
    }
}


// MARK: - FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance
extension CalendarViewController: FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
    
    // 달력 뷰 높이 등 크기 변화 감지(UI 동적 레이아웃 맞출 때 활용)
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        customView.calendarViewHeightConstraint.constant = bounds.height
        view.layoutIfNeeded()
    }


    // 커스텀 셀 이미지 표시
    func calendar(_ calendar: FSCalendar, cellFor date: Date, at position: FSCalendarMonthPosition) -> FSCalendarCell {
        let cell = calendar.dequeueReusableCell(withIdentifier: CalendarCell.reuseIdentifier, for: date, at: position) as! CalendarCell
        
        // 오늘 날짜인지 비교해서 전달
        let calendar = Calendar.current
        cell.isToday = calendar.isDateInToday(date)
        cell.isCurrentMonth = (position == .current)
        
        // 날짜 -> String(key) 변환
        let dateString = date.toDateKey()
        
        if position == .current {
            if let posts = homeViewModel.group.value?.postsByDate[dateString], let firstPost = posts.first {
                // 해당 날짜에 이미지가 있다면첫 이미지만 표시
                cell.setImage(url: firstPost.imageURL)
            } else {
                cell.setGrayBox()
            }
        } else {
            cell.setDarkGrayBox()
        }
        return cell
    }
    
    // 셀 터치 감지
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        
        // 현재 월이 아니면 return
        guard monthPosition == .current else { return }
        let dateString = date.toDateKey()
        guard let posts = homeViewModel.group.value?.postsByDate[dateString], !posts.isEmpty else { return }

        let viewer = ImageScrollViewController(posts: posts, selectedDate: dateString, homeViewModel: homeViewModel)
        // viewer.coordinator = coordinator
        viewer.modalPresentationStyle = .fullScreen
        
        /// onPresent 콜백 호출
        onPresent?(viewer)
    }
}

#Preview {
    CalendarViewController(homeViewModel: StubHomeViewModel())
}
