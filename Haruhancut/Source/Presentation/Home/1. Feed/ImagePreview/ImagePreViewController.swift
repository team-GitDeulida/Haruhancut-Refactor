//  ImagePreViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/19/25.
//

import UIKit

final class ImagePreViewController: UIViewController {
    private let customView: ImagePreView
    
    // MARK: - Initializer
    init(image: UIImage) {
        self.customView = ImagePreView(image: image)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - LifeCycle
    override func loadView() {
        self.view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addTarget()
    }
    
    // MARK: - addTarget
    private func addTarget() {
        customView.scrollView.delegate = self
        customView.closeButton.addTarget(self, action: #selector(closePreview), for: .touchUpInside)
        customView.saveButton.addTarget(self, action: #selector(savePreview), for: .touchUpInside)
    }
}

extension ImagePreViewController {
    @objc private func closePreview() {
        dismiss(animated: true)
    }
    
    @objc private func savePreview() {
        // 앨범에 사진 저장
        UIImageWriteToSavedPhotosAlbum(customView.image, nil, nil, nil)
        
        // 저장 알림 표시
        AlertManager.showAlert(on: self, title: "사진 저장", message: "사진이 앨범에 저장되었습니다.")
    }
}

extension ImagePreViewController: UIScrollViewDelegate {
    // 줌 대상 지정
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return customView.imageView
    }
}

#Preview {
    ImagePreViewController(image: UIImage())
}
