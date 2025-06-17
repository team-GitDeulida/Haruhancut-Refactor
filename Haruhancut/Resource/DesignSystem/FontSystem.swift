//
//  FontSystem.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import UIKit

extension UIFont {
    enum HCFont: String {
        case black = "Pretendard-Black"
        case bold = "Pretendard-Bold"
        case extraBold = "Pretendard-ExtraBold"
        case extraLight = "Pretendard-ExtraLight"
        case light = "Pretendard-Light"
        case medium = "Pretendard-Medium"
        case regular = "Pretendard-Regular"
        case semiBold = "Pretendard-SemiBold"
        case thin = "Pretendard-Thin"
    }
}

// 커스텀 폰트
extension UIFont {
    static func hcFont(_ font: HCFont, size: CGFloat) -> UIFont {
        return UIFont(name: font.rawValue, size: size) ?? UIFont.systemFont(ofSize: size)
    }
}

// 하루한컷 프리셋 폰트
extension UIFont {
    static var titleFont: UIFont {
        hcFont(.bold, size: 24)
    }

    static var bodyFont: UIFont {
        hcFont(.regular, size: 16)
    }

    static var captionFont: UIFont {
        hcFont(.medium, size: 12)
    }
}


// ----------------------------------------------------------------- //
// SwiftUI 대응

import SwiftUI

extension Font {
    static var hcTitle: Font {
        Font.custom("Pretendard-Bold", size: 24)
    }

    static var hcBody: Font {
        Font.custom("Pretendard-Regular", size: 16)
    }

    static var hcCaption: Font {
        Font.custom("Pretendard-Medium", size: 12)
    }
}


final class FontView: UIView {
    
    // MARK: - UI Component
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .titleFont
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "title size 24"
        return label
    }()
    
    private lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.font = .bodyFont
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "body size 16"
        return label
    }()
    
    private lazy var captionLabel: UILabel = {
        let label = UILabel()
        label.font = .captionFont
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "caption size 12"
        return label
    }()
    
    private lazy var hStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, bodyLabel, captionLabel])
        stackView.axis = .vertical
        stackView.spacing = 16
        return stackView
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
        backgroundColor = .systemBackground
        addSubview(hStackView)
        hStackView.translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            hStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            hStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hStackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}

#Preview {
    FontView()
}
