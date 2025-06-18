//
//  Label.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import UIKit
import ScaleKit

final class HCLabel: UILabel {
    
    enum LabelType {
        case main(text: String)              // 큰 제목
        case sub(text: String)               // 부제목
        case commentAuther(text: String)     // 댓글 작성자
        case commentContent(text: String)    // 댓글 본문
        case custom(text: String, font: UIFont, color: UIColor)   // 커스텀 크기
        case feedNickname(text: String)      // 피드 닉네임
        case feedTime(text: String)           // 피드 시간
    }
    
    init(type: LabelType) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        configure(type: type)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure(type: LabelType) {
        numberOfLines = 0
        
        switch type {
        case .main(let text):
            textColor = .mainWhite
            font = UIFont.hcFont(.bold, size: 20.scaled)
            self.text = text
        case .sub(let text):
            textColor = .gray
            font = UIFont.hcFont(.semiBold, size: 15.scaled)
            self.text = text
        case .commentAuther(let text):
            textColor = .mainWhite
            font = UIFont.hcFont(.semiBold, size: 12.scaled)
            self.text = text
        case .commentContent(let text):
            textColor = .mainWhite.withAlphaComponent(0.8)
            font = UIFont.hcFont(.semiBold, size: 12.scaled)
            self.text = text
        case .custom(let text, let customFont, let customColor):
            textColor = customColor
            font = customFont
            self.text = text
        case .feedNickname(let text):
            textColor = .mainWhite
            font = .hcFont(.extraBold, size: 14)
            self.text = text
        case .feedTime(let text):
            textColor = .Gray300
            font = .hcFont(.extraBold, size: 14)
            self.text = text
        }
    }
}

