//  ProfileViewView.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import UIKit
import RxRelay

final class ProfileSettingView: UIView {
    
    let nickname: String
    let selectedRelay = BehaviorRelay<UIImage?>(value: nil)
    
    // MARK: - 콜백 클로저
    var onRequestPresentImagePicker: ((UIImagePickerController.SourceType) -> Void)?
    
    // MARK: - UI Component
    private lazy var mainLabel: UILabel = HCLabel(type: .main(text: "\(self.nickname) 님의 프로필을 설정해 주세요"))
    private lazy var subLabel: UILabel = HCLabel(type: .sub(text: "지금은 넘어가도 돼요!"))
    private lazy var hStackView: UIStackView = {
        let st = UIStackView(arrangedSubviews: [
            mainLabel,
            subLabel
        ])
        st.spacing = 10
        st.axis = .vertical
        st.distribution = .fillEqually // 모든 뷰가 동일한 크기
        // 뷰의 크기를 축 반대 방향으로 꽉 채운다
        // 세로 스택일 경우, 각 뷰의 가로 너비가 스택의 가로폭에 맞춰진다
        st.alignment = .fill
        return st
    }()
    lazy var profileImageView: ProfileImageView = {
        let imageView = ProfileImageView(size: 100, iconSize: 60)
        imageView.onCameraTapped = { [weak self] in
            guard let self = self else { return }
            self.onRequestPresentImagePicker?(.photoLibrary)
        }
        return imageView
    }()
    var selectedImage: UIImage?
    lazy var nextButton: UIButton = HCNextButton(title: "완료")
    let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.color = .lightGray
        return indicator
    }()
    
    // MARK: - Initializer
    init(nickname: String) {
        self.nickname = nickname
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .background
        
        [hStackView, profileImageView, nextButton, activityIndicator].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // MARK:  hStack
            hStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 30),
            hStackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            // MARK: - ProfileImage
            profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            profileImageView.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor),
            
            
            // MARK: - NextBtn
            nextButton.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            nextButton.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor),
            nextButton.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            nextButton.heightAnchor.constraint(equalToConstant: 50),
        
            // MARK: - Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
}

#Preview {
    ProfileSettingViewController(loginViewModel: StubLoginViewModel())
}
