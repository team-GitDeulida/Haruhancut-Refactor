//
//  AddMemberCircleView.swift
//  Haruhancut
//
//  Created by 김동현 on 6/19/25.
//

import UIKit

// MARK: - 초대용 뷰
final class AddMemberCircleView: UIView {
    // 탭 클릭
    var onTap: (() -> Void)?
    
    private lazy var circleView: UIView = {
        let v = UIView()
        v.backgroundColor = .gray   // 강조색
        v.translatesAutoresizingMaskIntoConstraints = false
        v.clipsToBounds = true
        return v
    }()
    private lazy var plusImage: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "plus"))
        iv.tintColor = .white
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    private lazy var hStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [ circleView ])
        sv.axis = .horizontal
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    init() {
        super.init(frame: .zero)
        setup()
        setupConstraints()
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutIfNeeded()
        // 원형
        let r = circleView.bounds.width / 2
        circleView.layer.cornerRadius = r
    }
    
    private func setup() {
        addSubview(hStack)
        circleView.addSubview(plusImage)
    }
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 전체 스택
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            hStack.topAnchor.constraint(equalTo: topAnchor),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // circle 크기
            circleView.widthAnchor.constraint(equalToConstant: 60.scaled),
            circleView.heightAnchor.constraint(equalTo: circleView.widthAnchor),
            
            // plusImage 중앙
            plusImage.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            plusImage.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
        ])
    }
    @objc private func didTap() {
        onTap?()
    }
}
