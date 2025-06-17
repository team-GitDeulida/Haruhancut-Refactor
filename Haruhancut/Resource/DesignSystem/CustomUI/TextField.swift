//
//  TextField.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//

import UIKit
import ScaleKit

final class HCTextField: UITextField {
    
    init(placeholder: String) {
        super.init(frame: .zero)
        self.placeholder = placeholder
        self.textColor = .mainWhite
        self.tintColor = .mainWhite
        self.backgroundColor = .Gray500
        self.layer.cornerRadius = 10.scaled
        self.addLeftPadding()
        self.setPlaceholderColor(color: .Gray200)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UITextField {
    func addLeftPadding() {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: DynamicSize.scaledSize(12), height: DynamicSize.scaledSize(50)))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    func setPlaceholderColor(color: UIColor) {
        guard let string = self.placeholder else {
            return
        }
        attributedPlaceholder = NSAttributedString(string: string, attributes: [.foregroundColor: color])
    }
}
