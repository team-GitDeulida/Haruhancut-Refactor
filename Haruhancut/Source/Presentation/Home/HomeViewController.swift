//  HomeViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import UIKit

final class HomeViewController: UIViewController {

    
    // MARK: - Variable
    weak var coordinator: HomeCoordinator?
    private let homeViewModel: HomeViewModelType
    var dataViewControllers: [UIViewController] { [feedVC, calendarVC] }
    var currentPage: Int = 0 {
        didSet {
            let direction: UIPageViewController.NavigationDirection = oldValue <= self.currentPage ? .forward : .reverse
            self.pageViewController.setViewControllers([dataViewControllers[self.currentPage]],
                                                       direction: direction,
                                                       animated: true)
        }
    }
    
    
    // MARK: - UI Component
    private let segmentedBar: CustomSegmentedBarView = {
        let segment = CustomSegmentedBarView(items: ["피드", "캘린더"])
        return segment
    }()
    private lazy var pageViewController: UIPageViewController = {
        let vc = UIPageViewController(transitionStyle: .scroll,
                                      navigationOrientation: .horizontal)
        vc.setViewControllers([self.dataViewControllers[0]],
                              direction: .forward,
                              animated: true)
        vc.delegate = self
        vc.dataSource = self
        return vc
    }()
    
    private lazy var feedVC: FeedViewController = {
        let vc = FeedViewController(homeViewModel: homeViewModel)
        vc.coordinator = self.coordinator
        
        // 사진 or 앨범 선택 알림창은 Home에서 알림 띄우기
        vc.onPresentChooseAlert = { [weak self] alert in
            self?.present(alert, animated: true)
        }
        
        // 앨범 알림창은 Home에서 알림 띄우기
        vc.onPresenAlbum = { [weak self] alert in
            self?.present(alert, animated: true)
        }
        
        return vc
    }()
    
    private lazy var calendarVC: CalendarViewController = {
        let vc = CalendarViewController(homeViewModel: homeViewModel)
        vc.coordinator = self.coordinator
        
        vc.onPresent = { [weak self] presentedVC in
            self?.present(presentedVC, animated: true)
        }
        return vc
    }()
    
    // MARK: - Initializer
    init(homeViewModel: HomeViewModelType) {
        self.homeViewModel = homeViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavi()
        setupUI()
        setupConstraints()
    }

    // MARK: - UI
    private func setupNavi() {
        /// 네비게이션 버튼 색상
        self.navigationController?.navigationBar.tintColor = .mainWhite
        
        /// 네비게이션 제목
        segmentedBar.sizeToFit() // 글자 길이에 맞게 label 크기 조정
        self.navigationItem.titleView = segmentedBar
        
        /// 좌측 네비게이션 버튼
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "list.bullet"),
            style: .plain,
            target: self,
            action: #selector(startMembers))
        
        /// 우측 네비게이션 버튼
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "person.fill"),
            style: .plain,
            target: self,
            action: #selector(startProfile))
        
        /// 자식 화면에서 뒤로가기
        let backItem = UIBarButtonItem()
        backItem.title = "홈으로"
        navigationItem.backBarButtonItem = backItem
    }
    
    private func setupUI() {
        view.backgroundColor = .background
        
        [segmentedBar, pageViewController.view].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        segmentedBar.segmentedControl.addTarget(self, action: #selector(changeValue), for: .valueChanged)
        segmentedBar.segmentedControl.selectedSegmentIndex = 0
        changeValue(control: segmentedBar.segmentedControl)
    }
    
    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    /// 세그먼트 변경 이벤트 핸들러
    @objc private func changeValue(control: UISegmentedControl) {
        self.currentPage = control.selectedSegmentIndex
        segmentedBar.moveUnderline(animated: true)
    }
    
    /// 프로필 화면 이동
    @objc private func startProfile() {
         coordinator?.startProfile()
    }
    
    /// 그룹 화면 이동
    @objc private func startMembers() {
         coordinator?.startMembers()
    }
}

extension HomeViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let viewController = pageViewController.viewControllers?[0], let index = self.dataViewControllers.firstIndex(of: viewController) else { return }
        self.currentPage = index
        segmentedBar.segmentedControl.selectedSegmentIndex = index
        segmentedBar.moveUnderline(animated: true)
    }
}

extension HomeViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = self.dataViewControllers.firstIndex(of: viewController), index - 1 >= 0 else { return nil }
        return self.dataViewControllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = self.dataViewControllers.firstIndex(of: viewController), index + 1 < self.dataViewControllers.count else { return nil }
        return self.dataViewControllers[index + 1]
    }
}

#Preview {
    UINavigationController(rootViewController: HomeViewController(homeViewModel: StubHomeViewModel()))
}

