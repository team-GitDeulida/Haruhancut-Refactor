//  SettingViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/20/25.
//

import UIKit
import RxSwift
import RxRelay
import SafariServices

final class SettingViewController: UIViewController {
    weak var coordinator: HomeCoordinator?
    private let settingViewModel: SettingViewModelType
    private let homeViewModel: HomeViewModelType
    private let customView = SettingView()
    private let disposeBag = DisposeBag()
    
    // MARK: - Event
    private let notificationToggleSubject = PublishSubject<Bool>()
    private let cellSelectedSubject     = PublishSubject<IndexPath>()
    
    // MARK: - Initializer
    init(settingViewModel: SettingViewModelType,
         homeViewModel: HomeViewModelType
    ) {
        self.settingViewModel = settingViewModel
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
    
    /// 사용자가 알림을 설정 앱에서 끄고 돌아왔을 경우도 감지를 위함
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // 알림 권한이 꺼졌다면 알림 토글도 꺼짐으로 표시
        checkNotificationAuthorization { [weak self] isAuthorized in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if !isAuthorized {
                    self.resetNotificationToggleToOff()
                }
            }
        }
    }

    
    // MARK: - setDelegate
    private func setDelegate() {
        customView.tableView.delegate = self
        customView.tableView.dataSource = self
    }

    // MARK: - Bindings
    private func bindViewModel() {
        let inut = SettingViewModel.Input(logoutTapped: customView.logoutButton.rx.tap.asObservable(),
                                          notificationToggleTapped: notificationToggleSubject.asObservable(),
                                          cellTapped: cellSelectedSubject.asObservable())
        
        let output = settingViewModel.transform(input: inut)
        
        /// 로그아웃 버튼 탭
        output.logoutResult
            .drive(onNext: { [weak self] logoutResult in
                guard let self = self else { return }
                switch logoutResult {
                case .success:
                    self.coordinator?.startLogin()
                case .failure:
                    AlertManager.showError(on: self, message: "홈으로 이동")
                }
            }).disposed(by: disposeBag)
        
        /// 알림 스위치 탭
        output.notificationResult
            .drive(onNext: { isOn in
                if isOn {
                    self.checkNotificationAuthorization { isAuthorized in
                        DispatchQueue.main.async {
                            if isAuthorized {
                                /// 알림 권한이 있으면 on
                                self.settingViewModel.alertOn()
                            } else {
                                /// 알림 권한이 없으면 off 유지 + UI 토글 원래대로 되돌리기
                                self.showNotificationPermissionAlert()
                                
                                /// 강제로 토글 false로 되돌림
                                self.resetNotificationToggleToOff()
                            }
                        }
                    }
                } else {
                    /// off일때는 그대로 유지
                    self.settingViewModel.alertOff()
                }
            })
            .disposed(by: disposeBag)
        
        /// 셀 선택
        output.selectionResult
            .drive(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                let option = self.customView.sections[indexPath.section].options[indexPath.row]
                switch option {
                case .toggle:
                    break
                case .version:
                    print("버전 정보 보기")
                case .privacyPolicy:
                    guard let url = URL(string: Constants.Notion.privatePolicy) else { return }
                    let safariVC = SFSafariViewController(url: url)
                    self.present(safariVC, animated: true)
                case .announce:
                    guard let url = URL(string: Constants.Notion.announce) else { return }
                    let safariVC = SFSafariViewController(url: url)
                    self.present(safariVC, animated: true)
                case .logout:
                    print("로그아웃 클릭됨")
                case .withdraw:
                    print("회원 탈퇴 클릭됨")
                    AlertManager.showConfirmation(on: self, title: "회원탈퇴", message: "정말로 탈퇴하시겠습니까?") { [weak self] in
                        guard let self = self else { return }
                        let uid = self.settingViewModel.user.uid
                        
                        self.settingViewModel.deleteUser(uid: uid)
                            .drive(onNext: { [weak self] success in
                                if success {
                                    self?.coordinator?.startLogin()
                                } else {
                                    AlertManager.showError(on: self!, message: "회원 탈퇴에 실패했습니다.")
                                }
                            })
                            .disposed(by: self.disposeBag)
                    }
                }
            })
            .disposed(by: disposeBag)

    }
}

extension SettingViewController {
    // MARK: - 토글 원래대로 되돌리는 함수
    private func resetNotificationToggleToOff() {
        // tableView 다시 그려서 toggle false 상태 반영
        self.customView.sections[0].options[0] = .toggle(title: "알림 설정", isOn: false)
        self.customView.tableView.reloadSections(IndexSet(integer: 0), with: .none)
        UserDefaultsManager.shared.setNotificationEnabled(enabled: false)
    }

    
    // MARK: - 현재 앱의 알림 권한 상태를 확인
    func checkNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completion(settings.authorizationStatus == .authorized)
        }
    }

    // MARK: - 설정 앱으로 이동 함수
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    // MARK: - 사용자에게 설정으로 유도하는 알림창
    func showNotificationPermissionAlert() {
        let alert = UIAlertController(
            title: "알림이 비활성화되어 있어요",
            message: "알림을 받으려면 설정 > 하루한컷에서 접근 권한을 허용해주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default, handler: { _ in
            self.openAppSettings()
        }))
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

#Preview {
    SettingViewController(settingViewModel: StubSettingViewModel(),
                          homeViewModel: StubHomeViewModel())
}

extension SettingViewController: UITableViewDataSource {
    
    // 섹션 개수(섹션에서만 사용)
    func numberOfSections(in tableView: UITableView) -> Int {
        return customView.sections.count
    }
    
    // 헤더 타이틀(섹션에서만 사용)
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return customView.sections[section].header
    }
    
    // 헤더가 화면에 나타나기 직전에 호출(섹션에서만 사용)
    func tableView(_ tableView: UITableView,
                   willDisplayHeaderView view: UIView,
                   forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        // 텍스트 색
        header.textLabel?.textColor = .hcColor
    }
    
    // 섹션별 행 개수
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return customView.sections[section].options.count
    }
    
    // 셀 구성
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let option = customView.sections[indexPath.section].options[indexPath.row]
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SettingCell.reuseIdentifier, for: indexPath) as? SettingCell else {
            return UITableViewCell()
        }
        cell.bindeCell(option: option)
        cell.selectionStyle = .none
        
        
        // MARK: - 토글 스위치 변경 시 Subject로 전송
        if option.toggleValue != nil {
            cell.toggleSwitch.rx.isOn
                .skip(1)
                .bind(to: notificationToggleSubject)
                .disposed(by: disposeBag)
        }
        return cell
    }
}

extension SettingViewController: UITableViewDelegate {
    func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        // let option = sections[indexPath.section].options[indexPath.row]
        tv.deselectRow(at: indexPath, animated: true)
        
        // MARK: - 셀 선택 시 Subject 으로 전송
        cellSelectedSubject.onNext(indexPath)
    }
}
