//  NicknameSettingViewView.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import UIKit

final class NicknameSettingView: UIView {
    
    // MARK: - Dynamic
    private var nextButtonBottonConstraint: NSLayoutConstraint?
    
    // MARK: - UI Component
    private lazy var mainLabel: UILabel = HCLabel(type: .main(text: "사용하실 닉네임을 입력해주세요."))
    private lazy var subLabel: UILabel = HCLabel(type: .sub(text: "닉네임은 언제든지 변경할 수 있어요!"))
    lazy var textField: UITextField = HCTextField(placeholder: "닉네임")
    private lazy var hStackView: UIStackView = {
        let st = UIStackView(arrangedSubviews: [
            mainLabel,
            subLabel,
        ])
        st.spacing = 10
        st.axis = .vertical
        st.distribution = .fillEqually // 모든 뷰가 동일한 크기
        /// 뷰의 크기를 축 반대 방향으로 꽉 채운다
        /// 세로 스택일 경우, 각 뷰의 가로 너비가 스택의 가로폭에 맞춰진다
        st.alignment = .fill
        return st
    }()
    lazy var nextButton: UIButton = HCNextButton(title: "다음")
    
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        
        if let constraint = nextButtonBottonConstraint {
            self.bindKeyboard(to: constraint)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 외부 터치 시 키보드 내리기
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        endEditing(true)
    }

    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .background
        [hStackView, textField, nextButton].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    // MARK: - Constraints
    private func setupConstraints() {
        
        nextButtonBottonConstraint = nextButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10)
        
        
        NSLayoutConstraint.activate([
            // MARK:  hStack
            hStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 30),
            hStackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            // MARK: - textField
            textField.topAnchor.constraint(equalTo: hStackView.bottomAnchor, constant: 30),  // y축 위치
            textField.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor), // x축 위치
            textField.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20), // 좌우 패딩
            textField.heightAnchor.constraint(equalToConstant: 50), // 버튼 높이
            
            // MARK: - NextBtn
            nextButton.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
            nextButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),// 좌우 패딩
            nextButton.heightAnchor.constraint(equalToConstant: 50), // 버튼 높이
                    nextButtonBottonConstraint!
        ])
    }
}

#Preview {
    NicknameSettingViewController(loginViewModel: StubLoginViewModel())
}



