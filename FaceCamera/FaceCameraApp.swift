//
//  FaceCameraApp.swift
//  FaceCamera
//
//  Created by user on 12/2/24.
//
//

import SwiftUI
import AVFoundation
import Vision
import CoreML

struct ContentView: View {
    @State private var captureSession: AVCaptureSession?
    @State private var model: VNCoreMLModel?
    @State private var emotion: String = ""
    @State private var backgroundImage: Image?
    
    var body: some View {
        ZStack {
            if let backgroundImage = backgroundImage {
                backgroundImage
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            } else {
                Color.gray
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack {
                Text("情緒: \(emotion)")
                    .font(.largeTitle)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .padding(.top, 40)
                Spacer()
                CameraPreviewView(captureSession: $captureSession)
                    .frame(height: 300)
                    .cornerRadius(20)
                    .padding()
            }
        }
        .onAppear {
            setupCamera()
            setupModel()
        }
    }
    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .vga640x480
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession?.canAddInput(videoInput) == true else {
            return
        }
        captureSession?.addInput(videoInput)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.setSampleBufferDelegate(CamradDelegate { pixelBuffer in processBuffer(pixelBuffer)}, queue: DispatchQueue(label: "videoQueue"))
        
        guard captureSession?.canAddOutput(videoOutput) == true else { return }
        captureSession?.addOutput(videoOutput)
        
        captureSession?.startRunning()
    }
    
    func setupModel() {
        guard let mlModel = try? EmotionClassifier(configuration: MLModelConfiguration()).model else {
            fatalError("無法加載 ML 模型")
        }
        model = try? VNCoreMLModel(for: mlModel)
    }
    
    func processBuffer(_ pixelBuffer: CVPixelBuffer) {
        guard let model = model else { return }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation], let firstResult = results.first else { return }
            
            DispatchQueue.main.async {
                self.emotion = firstResult.identifier
                updateBackground(forEmotion: firstResult.identifier)
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    func updateBackground(forEmotion emotion: String) {
        switch emotion {
        case "Happy":
            backgroundImage = Image("happy") // 使用 Assets 中的圖片
        case "Angry":
            backgroundImage = Image("angry") // 使用 Assets 中的圖片
        case "Sad":
            backgroundImage = Image("cry") // 使用 Assets 中的圖片
        default:
            backgroundImage = nil  // 默認背景色
        }
    }
}

struct CameraPreviewView: UIViewControllerRepresentable {
    @Binding var captureSession: AVCaptureSession?
    
    func makeUIViewController(context: Context) -> CameraPreviewController {
        let controller = CameraPreviewController()
        controller.captureSession = captureSession
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraPreviewController, context: Context) {
        uiViewController.captureSession = captureSession
    }
}
class CameraPreviewController: UIViewController {
    var captureSession: AVCaptureSession? {
        didSet {
            if let sesion = captureSession {
                previewLayer.session = captureSession
            }
        }
    }
    
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewLayer = AVCaptureVideoPreviewLayer()
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }
}

class CamradDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let processBuffer: (CVPixelBuffer) -> Void
    
    init(processBuffer: @escaping (CVPixelBuffer) -> Void) {
        self.processBuffer = processBuffer
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        processBuffer(pixelBuffer)
    }
}

@main
struct FaceCameraApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
    
