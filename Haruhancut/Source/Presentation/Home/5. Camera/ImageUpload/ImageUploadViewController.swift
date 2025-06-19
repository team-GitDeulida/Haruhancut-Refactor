//  ImageUploadViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import UIKit
import RxSwift

final class ImageUploadViewController: UIViewController {
    weak var coordinator: HomeCoordinator?
    private let homeViewModel: HomeViewModelType
    private let customView: ImageUploadView
    private let disposeBag = DisposeBag()
    
    // MARK: - Initializer
    init(image: UIImage, homeViewModel: HomeViewModelType) {
        self.customView = ImageUploadView(image: image)
        self.homeViewModel = homeViewModel
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
        customView.uploadButton.addTarget(self,
                                          action: #selector(uploadAndBackToHome),
                                          for: .touchUpInside)
    }

    // MARK: - Bindings
    private func bindViewModel() {

    }
    
    @objc private func uploadAndBackToHome() {
        customView.uploadButton.isEnabled = false
        customView.alpha = 0.5
        
        homeViewModel.uploadPost(image: customView.image)
            .drive(onNext: { [weak self] success in
                guard let self = self else { return }
                 self.coordinator?.backToHome()
                
                if success {
                    self.customView.uploadButton.isEnabled = true
                    self.customView.uploadButton.alpha = 1.0
                } else {
                    AlertManager.showAlert(on: self,
                                           title: "업로드 실패",
                                           message: "사진 업로드에 실패하였습니다.")
                    self.customView.uploadButton.isEnabled = true
                    self.customView.uploadButton.alpha = 1.0
                }
            }).disposed(by: disposeBag)
        
    }
}

#Preview {
    ImageUploadViewController(image: UIImage(),
                              homeViewModel: StubHomeViewModel())
}
