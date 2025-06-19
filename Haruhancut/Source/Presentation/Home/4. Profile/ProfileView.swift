//  ProfileViewView.swift
//  Haruhancut
//
//  Created by 김동현 on 6/19/25.
//

import UIKit

final class ProfileView: UIView {
    
    var nickname: String
    var loadingView: UIView?
    
    // MARK: - UI Component
    lazy var profileImageView: ProfileImageView = {
        let imageView = ProfileImageView(size: 100, iconSize: 60)
        return imageView
    }()

    private lazy var nicknameLabel: HCLabel = {
       let label = HCLabel(type: .main(text: nickname))
        return label
    }()
    
    private lazy var editButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "pencil"), for: .normal)
        button.tintColor = .mainWhite
        /// button.addTarget(self, action: #selector(navigateToNicknameSetting), for: .touchUpInside)
        return button
    }()
    
    private lazy var hStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [profileImageView, UIView(), nicknameLabel, UIView(), editButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        
        return stack
    }()
    
    private lazy var collectionView: UICollectionView = {
        let spacing: CGFloat = 1
        let columns: CGFloat = 3

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = .zero

        // 셀 너비 계산
        let totalSpacing = (columns - 1) * spacing
        let itemWidth = (UIScreen.main.bounds.width - totalSpacing) / columns
        
        // 높이를 너비의 1.5배로 설정
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 1.5)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        /// cv.register(ProfilePostCell.self, forCellWithReuseIdentifier: ProfilePostCell.identifier)
        cv.backgroundColor = .clear
        return cv
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
        [hStack, collectionView].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 30),
            hStack.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor),
            hStack.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            collectionView.topAnchor.constraint(equalTo: hStack.bottomAnchor, constant: 50),
            collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
}

#Preview {
    ProfileView(nickname: "stub-nickname")
}

