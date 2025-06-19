//  CameraViewView.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import UIKit

final class CameraView: UIView {
    
    // MARK: - UI Component
    let cameraView: UIView = {
       let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var cameraBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "button.programmable"), for: .normal)
        btn.tintColor = .mainWhite
        btn.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 70.scaled), forImageIn: .normal)
        btn.imageView?.contentMode = .scaleAspectFit
        return btn
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
        [cameraView, cameraBtn].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

    }

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // MARK: - cameraView
            // 위치
            cameraView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 150),
            cameraView.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor),
            
            // 크기
            cameraView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            cameraView.heightAnchor.constraint(equalTo: cameraView.widthAnchor),
            
            // MARK: - cameraBtn
            cameraBtn.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -50.scaled),
            cameraBtn.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor),
            
        ])
    }
}

#Preview {
    CameraView()
}
