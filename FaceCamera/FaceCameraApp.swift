//
//  FaceCameraApp.swift
//  FaceCamera
//
//  Created by user on 12/2/24.
//
//

import UIKit
import SwiftUI
import AVFoundation
import Vision
import CoreML

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var model: VNCoreMLModel!
    var emotionLabel: UILabel!
    var backgroundImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCamera()
        setupModel()
        setupUI()
        
        // 創建 SwiftUI 的 ContentView
        let contentView = ContentView()
        let hostingController = UIHostingController(rootView: contentView)
        
        // 添加為子控制器
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.didMove(toParent: self)
    }
    
    func setupCamera() {
        // 初始化相機捕抓會話
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .vga640x480 // 使用較低的解析度以支援舊設備
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("無法訪問相機： \(error)")
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            print("無法添加相機輸入")
            return
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ABGR]
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoOueue"))
        if (captureSession.canAddOutput(videoOutput)) {
            captureSession.addOutput(videoOutput)
        } else {
            print("無法添加視頻輸出")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    func setupModel() {
        // 加載 ML 模型
        guard let mlModel = try? EmotionClassifier(configuration: MLModelConfiguration()).model else {
            fatalError("無法加載 ML 模型")
        }
        do {
            model = try VNCoreMLModel(for: mlModel)
        } catch {
            fatalError("無法創建 VNCoreMLModel: \(error)")
        }
    }
    
    func setupUI() {
        // 設置背景圖層
        backgroundImageView = UIImageView(frame: view.bounds)
        backgroundImageView.contentMode = .scaleAspectFill
        view.addSubview(backgroundImageView)
        
        //設置情緒顯示標籤
        emotionLabel = UILabel(frame: CGRect(x: 20, y: 40, width: view.frame.width - 40, height: 50))
        emotionLabel.textColor = .white
        emotionLabel.font = UIFont.boldSystemFont(ofSize: 24)
        emotionLabel.textAlignment = .center
        emotionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        emotionLabel.layer.cornerRadius = 10
        emotionLabel.layer.masksToBounds = true
        view.addSubview(emotionLabel)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        let requestOptions: [VNImageOption: Any] = [:]
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation], let firstResult = results.first else {
                return
            }
            
            DispatchQueue.main.async {
                self.emotionLabel.text = "情緒: \(firstResult.identifier)"
                // 根據情緒變換背景，例如顯示圖庫中的嚮應圖片
                self.updateBackground(forEmotion: firstResult.identifier)
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options:  requestOptions)
        do {
            try handler.perform([request])
        } catch {
            print("處理請求時發生錯誤: \(error)")
        }
    }
    
    func updateBackground(forEmotion emotion: String) {
        switch emotion {
        case "Happy":
            backgroundImageView.image = UIImage(named: "Happy") // 使用 Assets 中的圖片
        case "Angry":
            backgroundImageView.image = UIImage(named: "Angry") // 使用 Assets 中的圖片
        case "Sad":
            backgroundImageView.image = UIImage(named: "Sad") // 使用 Assets 中的圖片
        default:
            backgroundImageView.image = nil // 默認背景色
            view.backgroundColor = UIColor.gray // 使用灰色背景
        }
    }
}
    
