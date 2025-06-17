//  LoginViewView.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import UIKit
import Lottie

final class LoginView: UIView {
    
    // MARK: - UI Component
    let animationView: LottieAnimationView = {
        let lottie = LottieAnimationView(name: "LottieCamera")
        return lottie
    }()
    
    private lazy var kakaoLoginButton = SocialLoginButton(type: .kakao,
                                                          title: "카카오로 계속하기")
    
    private lazy var appleLoginButton = SocialLoginButton(type: .apple,
                                                          title: "Apple로 계속하기")
    
    private lazy var stackView: UIStackView = {
        let st = UIStackView(arrangedSubviews: [
            kakaoLoginButton,
            appleLoginButton
        ])
        st.spacing = 10
        st.axis = .vertical
        st.distribution = .fillEqually
        st.alignment = .fill
        return st
    }()
    
    private let titleLabel: UILabel = {
        let label = HCLabel(type: .custom(text: "하루한컷",
                                          font: .logoFont,
                                          color: .mainWhite))
        return label
    }()

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .background
        [animationView, stackView, titleLabel].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            // MARK: - Lottie
            // 위치
            animationView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 220.scaled),
            animationView.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            // 크기
            animationView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.scaled),
            animationView.heightAnchor.constraint(equalToConstant: 200.scaled),
            
            // MARK: - StackView
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -50.scaled),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.scaled),
            stackView.heightAnchor.constraint(equalToConstant: 130.scaled),
            
            // MARK: - Title
            titleLabel.topAnchor.constraint(equalTo: animationView.bottomAnchor, constant: 20.scaled),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
}

#Preview {
    LoginViewController(viewModel: StubLoginViewModel())
}
