//  CameraViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

/*
 카메라 권한 추가
 <key>NSCameraUsageDescription</key>
 <string>카메라를 사용하여 사진을 촬영할 수 있습니다.</string>
 
 앨범 권한 추가
 <key>NSPhotoLibraryAddUsageDescription</key>
 <string>사진을 저장하기 위해 사진 보관함에 접근합니다.</string>

 */

import UIKit
import AVFoundation

final class CameraViewController: UIViewController {
    weak var coordinator: HomeCoordinator?
    private let customView = CameraView()
    
    // MARK: - 카메라
    private var captureSession: AVCaptureSession?               // 카메라 세션 객체
    private var previewLayer: AVCaptureVideoPreviewLayer?       // 카메라 화면을 보여줄 레이어
    
    // MARK: - 캡처 방식을 사용한다면 필요한 프로퍼티
    private let videoOutput = AVCaptureVideoDataOutput()        // 영상 프레임 출력(무음 캡처)
    private var currentImage: UIImage?                          // 가장 최근 프레임 저장용
    private var freezeImageView: UIImageView?                   // 캡처한 이미지 띄우는 용도
    
    // MARK: - 중복 카메라 설정 방지 플래그
    private var isCameraConfigured = false

    // MARK: - LifeCycle
    override func loadView() {
        self.view = customView
    }
    
    // MARK: - 중복설정 방지
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard !isCameraConfigured else { return }
        isCameraConfigured = true
        
        // 카메라 설정(백그라운드 스레드에서 실행)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.setupCamera()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addTarget()
        preparePreviewLayer()
    }
    
    // MARK: - 레이아웃 갱신(프레임 동기화)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // MARK: - 뷰의 레이아웃이 실제로 완료된 후에 cameraView.bounds가 실제 사이즈로 계산되어 frame = .zero가 아니므로 previewLayer?.frame = customView.cameraView.bounds가 정확한 위치와 크기로 적용된다.
        
        /// 프레임이 달라졌을 때만 previewLayer 위치/크기 갱신
        if previewLayer?.frame != customView.cameraView.bounds {
            previewLayer?.frame = customView.cameraView.bounds
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        /// 다음 뷰가 previewVC이면 종료하지 않고 리턴하겠다.
        // TODO: -
        
        /// 1. 화면을 벗어날 때 세션 종료
        captureSession?.stopRunning()
        captureSession = nil
        
        /// 2. 미리보기 레이어 제거
        previewLayer?.removeFromSuperlayer()
        
        /// 3. 재진입시 카메라 다시 설정(setupCamera 호출)되도록 플래그 초기화
        isCameraConfigured = false
    }
    
    // MARK: - addTarget
    private func addTarget() {
        customView.cameraBtn.addTarget(self, action: #selector(captureCurrentFrame), for: .touchUpInside)
    }

    // MARK: - Bindings
    private func bindViewModel() {

    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // MARK: - 카메라 설정
    private func setupCamera() {
        /// 1. 권한 체크
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupCamera()
                } else {
                    DispatchQueue.main.async {
                        self?.showCameraPermissionAlert()
                    }
                }
            }
        default:
            DispatchQueue.main.async {
                self.showCameraPermissionAlert()
            }
            return
        }
        
        /// 2. 세션 설정
        let session = AVCaptureSession()
        session.sessionPreset = .photo // 고해상도 사진 모드
        
        /// 3. 후면 카메라를 입력으로 설정
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("카메라 접근 실패")
            return
        }
        
        /// 4 세션에 입력 추가
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        /// 5 비디오 출력 설정
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        /// 6 세션 저장 및 시작
        self.captureSession = session
        session.startRunning()
        
        /// 7 메인 스레드에서 previewLayer와 세션 연결
        DispatchQueue.main.async { [weak self] in
            self?.previewLayer?.session = session
        }
    }
    
    // MARK: - 카메라 미리보기 layer 설정
    private func preparePreviewLayer() {
        let preview = AVCaptureVideoPreviewLayer()
        preview.videoGravity = .resizeAspectFill               // 화면 채우면서 비율 유지
        preview.frame = customView.cameraView.bounds           // 초기 프레임 설정
        customView.cameraView.layer.addSublayer(preview)       // cameraView에 layer 추가
        self.previewLayer = preview                            // 나중에 참조할 수 있도록 저장
    }
    
    // TODO: -
    // MARK: - 프레임 캡처하여 저장 (무음 촬영)
    @objc private func captureCurrentFrame() {
        guard let image = currentImage else {
            print("현재 프레임 없음")
            return
        }

        assert(Thread.isMainThread, "❌ UI 변경은 반드시 메인 스레드에서 수행해야 합니다")
        coordinator?.startToUpload(image: image, cameraType: .camera)
    }
    
    // MARK: - 카메라 설정 권한 -> 설정으로 이동
    private func showCameraPermissionAlert() {
        /// 설정창으로 이동
        let settingsAction = UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        AlertManager.showAlert(on: self,
                               title: "카메라 접근 권한 필요",
                               message: "카메라를 사용하려면 설정 > 하루한컷에서 접근 권한을 허용해주세요.",
                               actions: [cancelAction, settingsAction])
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            let uiImage = UIImage(cgImage: cgImage,
                                  scale: UIScreen.main.scale,
                                  orientation: .right) // 카메라 방향 보정
            self.currentImage = uiImage
        }
    }
}

#Preview {
    CameraViewController()
}
