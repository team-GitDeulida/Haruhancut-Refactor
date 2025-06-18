//  FeedViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import UIKit
import RxSwift

final class FeedViewController: UIViewController {
    weak var coordinator: HomeCoordinator?
    private let homeViewModel: HomeViewModelType
    private let customView = FeedView()
    private let disposeBag = DisposeBag()
    
    /// 이벤트 콜백 (Home에서 알람 울리기)
    var onPresentChooseAlert: ((UIAlertController) -> Void)?
    
    /// 이벤트 콜백 (Home에서 앨범 띄우기)
    var onPresenAlbum: ((UIViewController) -> Void)?
    
    // MARK: - Initializer
    init(homeViewModel: HomeViewModelType) {
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
        addtarget()
        bindViewModel()
    }
    
    // MARK: - addTarget
    private func addtarget() {
        self.customView.cameraBtn.addTarget(self, action: #selector(startCamera), for: .touchUpInside)
    }

    // MARK: - Bindings
    private func bindViewModel() {
        /// 포스트 바인딩
        homeViewModel.transform().todayPosts
            .drive(customView.collectionView.rx.items(
                cellIdentifier: FeedCell.reuseIdentifier,
                cellType: FeedCell.self)
            ) { _, post, cell in
                cell.configure(post: post)
            }
            .disposed(by: disposeBag)
    }
}


// MARK: - 카메라 버튼 클릭
extension FeedViewController {
    /// 카메라 버튼 클릭(카메라 or 앨범 선택 가능 알림창)
    @objc private func startCamera() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // 📷 사진 촬영
        alert.addAction(UIAlertAction(title: "카메라로 찍기", style: .default) { [weak self] _ in
             self?.coordinator?.startCamera()
        })

        // 🖼️ 앨범에서 선택
        alert.addAction(UIAlertAction(title: "앨범에서 선택", style: .default) { [weak self] _ in
             self?.presentImagePicker(sourceType: .photoLibrary)
        })

        // ❌ 취소
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        /// 직접 present 대신 콜백 위임!
        if let presentAlert = onPresentChooseAlert {
            presentAlert(alert)
        } else {
            // 혹시나 없으면 fallback (단, 이 경우는 hierarchy 경고 가능성 있음)
            present(alert, animated: true)
        }
    }
}

// MARK: - 앨범 선택 관련
extension FeedViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            print("❌ 해당 소스타입 사용 불가")
            return
        }
        
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = false
        
        // 부모에게 위임해서 present!
        if let presentAction = onPresenAlbum {
            presentAction(picker)
        } else {
            // 없으면 fallback (이 경우 경고 발생 가능)
            present(picker, animated: true)
        }
        
        // 이미지 선택 완료
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)

            if let image = info[.originalImage] as? UIImage {
                // ✅ 기존 업로드 흐름과 동일하게 처리
                coordinator?.startToUpload(image: image, cameraType: .gallary)
            }
        }
        
        // 선택 취소
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}


#Preview {
    FeedViewController(homeViewModel: StubHomeViewModel())
}
