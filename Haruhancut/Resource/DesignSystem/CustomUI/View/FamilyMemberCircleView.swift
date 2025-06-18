//
//  FamilyMemberCircleView.swift
//  Haruhancut
//
//  Created by 김동현 on 6/19/25.
//

import UIKit

// MARK: - FamilyMemberCircleView
final class FamilyMemberCircleView: UIView {
    
    private lazy var circleView: UIView = {
        let v = UIView()
        v.backgroundColor = .Gray300
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.layer.masksToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .gray
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .hcFont(.bold, size: 14)
        lbl.textColor = .mainWhite
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private lazy var hStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [ circleView, nameLabel ])
        sv.axis = .horizontal
        sv.alignment = .center
        sv.spacing = 12
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    var onProfileTapped: (() -> Void)?
    var image: UIImage? { imageView.image }
    
    init(name: String, imageURL: URL?) {
        super.init(frame: .zero)
        nameLabel.text = name
        setupViews()
        setupConstraints()
        loadImage(url: imageURL)
        setUpTapGesture()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 레이아웃이 완료된 후에 radius 설정
        layoutIfNeeded()
        let radius = circleView.bounds.width / 2
        circleView.layer.cornerRadius = radius
        imageView.layer.cornerRadius = radius
    }
    
    private func setupViews() {
        addSubview(hStack)
        circleView.addSubview(imageView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // stack 전체를 핀
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            hStack.topAnchor.constraint(equalTo: topAnchor),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // circleView 60×60 고정
            circleView.widthAnchor.constraint(equalToConstant: 60),
            circleView.heightAnchor.constraint(equalTo: circleView.widthAnchor),
            
            // imageView = circleView 크기
            imageView.leadingAnchor.constraint(equalTo: circleView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: circleView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: circleView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: circleView.bottomAnchor),
        ])
    }
    
    private func loadImage(url: URL?) {
        if let url = url {
            imageView.kf.setImage(with: url)
        } else {
            imageView.image = UIImage(systemName: "person.fill")
        }
    }
    
    private func setUpTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }
    @objc private func profileTapped() { onProfileTapped?() }
}
