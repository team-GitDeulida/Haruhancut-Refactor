//
//  ProfilePostCell.swift
//  Haruhancut
//
//  Created by 김동현 on 6/19/25.
//

import UIKit

final class ProfilePostCell: UICollectionViewCell {
    static let identifier = "ProfilePostCell"
    
    // 이미지 뷰: 셀의 배경 이미지를 보여줌
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill           // 셀 채우되 비율 유지
        iv.clipsToBounds = true                     // 셀 밖 이미지 자르기
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // 1. imageView를 contentView에 추가하고 전체 고정
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 외부에서 데이터를 받아 셀 구성
    func configure(with post: Post) {
        let url = URL(string: post.imageURL)
        imageView.kf.setImage(with: url)
    }
}
