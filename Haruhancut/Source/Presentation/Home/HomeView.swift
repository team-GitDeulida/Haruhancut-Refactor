////  HomeViewView.swift
////  Haruhancut
////
////  Created by 김동현 on 6/18/25.
////
//
//import UIKit
//
//final class HomeView: UIView {
//    
//    // MARK: - Variable
//    var currentPage: Int = 0 {
//        didSet {
//            let direction: UIPageViewController.NavigationDirection = oldValue <= self.currentPage ? .forward : .reverse
//        }
//    }
//    
//    // MARK: - UI Component
//    private let segmentedBar: CustomSegmentedBarView = {
//        let segment = CustomSegmentedBarView(items: ["피드", "캘린더"])
//        return segment
//    }()
//    
//    private lazy var pageViewController: UIPageViewController = {
//        let vc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
//    }()
//    
//    // MARK: - Initializer
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupUI()
//        setupConstraints()
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    // MARK: - UI Setup
//    private func setupUI() {
//        backgroundColor = .background
//        [segmentedBar].forEach {
//            self.addSubview($0)
//            $0.translatesAutoresizingMaskIntoConstraints = false
//        }
//    }
//
//    // MARK: - Constraints
//    private func setupConstraints() {
//        NSLayoutConstraint.activate([
//
//        ])
//    }
//}
//
//extension HomeView {
//    /// 세그먼트 변경 이벤트 핸들러
//    @objc private func changeValue(control: UISegmentedControl) {
//        self.currentPage = control.selectedSegmentIndex
//        segmentedBar.moveUnderline(animated: true)
//    }
//}
//
//#Preview {
//    HomeView()
//}
