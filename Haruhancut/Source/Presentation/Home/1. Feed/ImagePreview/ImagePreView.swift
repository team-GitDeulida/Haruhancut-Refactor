//  ImagePreViewView.swift
//  Haruhancut
//
//  Created by 김동현 on 6/19/25.
//

import UIKit

final class ImagePreView: UIView {
    
    let image: UIImage
    
    // MARK: - UI Component
    lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 3.0
        return sv
    }()

    lazy var imageView: UIImageView = {
        let iv = UIImageView(image: image)
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .black
        iv.tintColor = .gray
        return iv
    }()
    
    lazy var closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("닫기", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    lazy var saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("저장", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Initializer
    init(image: UIImage) {
        self.image = image
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .black

        [scrollView, closeButton, saveButton].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        scrollView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // scrollView가 전체 화면을 덮도록
            scrollView.topAnchor.constraint(equalTo: self.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            // imageView는 scrollView크기와 동일
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            

            // 닫기 버튼
            closeButton.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            
            // 저장 버튼
            saveButton.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 20),
            saveButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20)
        ])
    }
}

#Preview {
    ImagePreView(image: UIImage())
}
