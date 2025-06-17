//  BirthdaySettingViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import UIKit
import RxSwift

final class BirthdaySettingViewController: UIViewController {
    private let disposeBag = DisposeBag()
    weak var coordinator: LoginFlowCoordinator?
    private let loginViewModel: LoginViewModelType
    private let customView: BirthdaySettingView
    
    // MARK: - Initializer
    init(loginViewModel: LoginViewModelType) {
        self.loginViewModel = loginViewModel
        let nickname = loginViewModel.user.value?.nickname ?? "닉네임"
        self.customView = BirthdaySettingView(nickname: nickname)
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
        setupDatePicker()
        bindViewModel()
    }

    // MARK: - Bindings
    private func bindViewModel() {
        let input = LoginViewModel.BirthdayInput(
            birthdayDate: customView.datePicker.rx.date.asObservable(),
            nextBtnTapped: customView.nextButton.rx.tap.asObservable())
        let output = loginViewModel.transform(input: input)
        
        output.moveToProfile
            .drive(onNext: { _ in
                DispatchQueue.main.async {
                    self.coordinator?.showProfileSetting()
                }
            }).disposed(by: disposeBag)
    }
}

#Preview {
    BirthdaySettingViewController(loginViewModel: StubLoginViewModel())
}

extension BirthdaySettingViewController {

    private func setupDatePicker() {
        customView.datePicker.datePickerMode = .date
        customView.datePicker.preferredDatePickerStyle = .wheels
        customView.datePicker.locale = Locale(identifier: "ko-KR")
        customView.datePicker.addTarget(self, action: #selector(dateChange), for: .valueChanged)
        
        // ✅ 핵심: inputView를 datePicker로 지정
        customView.textField.inputView = customView.datePicker
        
        // ✅ 툴바를 inputAccessoryView로 설정
        customView.textField.inputAccessoryView = createToolbar()

        // ✅ 초기값을 2000년 1월 1일로 설정
        let defaultDate = Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? Date()
        customView.datePicker.date = defaultDate
        customView.textField.text = defaultDate.toKoreanDateKey()
    }
    
    private func showDatePickerAlert() {
        let alert = UIAlertController(title: "생년월일 선택", message: "\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)

        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.locale = Locale(identifier: "ko-KR")
        picker.date = customView.datePicker.date // 기존 값 유지
        picker.frame = CGRect(x: 0, y: 30, width: 270, height: 216)

        alert.view.addSubview(picker)

        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.customView.datePicker.date = picker.date
            self.customView.textField.text = picker.date.toKoreanDateKey()
            if var user = loginViewModel.user.value {
                user.birthdayDate = picker.date
                loginViewModel.user.accept(user)
            }
        }))

        present(alert, animated: true)
    }

    @objc private func dateChange(_ sender: UIDatePicker) {
        customView.textField.text = sender.date.toKoreanDateKey()
        if var user = loginViewModel.user.value {
            user.birthdayDate = sender.date
            loginViewModel.user.accept(user)
        }
    }
    
    // 툴바 추가
    private func createToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)
        toolbar.sizeToFit()
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "완료", style: .plain, target: self, action: #selector(donePressed))
        
        // "완료" 버튼을 오른쪽으로 보내기
        toolbar.setItems([flexibleSpace, doneButton], animated: true)

        return toolbar
    }

    @objc private func donePressed() {
        customView.textField.resignFirstResponder()
    }
}
