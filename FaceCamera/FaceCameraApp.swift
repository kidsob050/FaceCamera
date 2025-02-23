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

class GlobalSettings: ObservableObject {
    @Published var screenContrast: Double = 50
    @Published var isContrastAdjusting: Bool = false
}

struct MainView: View {
    @EnvironmentObject var settings: GlobalSettings
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gray
                    .edgesIgnoringSafeArea(.all)
                    .brightness((settings.screenContrast - 50) / 100)
                
                VStack(spacing: 20) {
                    Text("Face Camera App")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    NavigationLink(destination: ContentView()) {
                        Text("開始使用")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    
                    NavigationLink(destination: SettingsView()) {
                        Text("設定")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.purple)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationTitle("") // 空標題，避免顯示默認標題
            .navigationBarHidden(true) // 隱藏導航欄
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var settings: GlobalSettings
    
    var body: some View {
        ZStack {
            Color.gray
                .edgesIgnoringSafeArea(.all)
                .brightness((settings.screenContrast - 50) / 100)
            VStack {
                Text("設定頁面")
                    .font(.largeTitle)
                    .foregroundColor(.yellow)
                
                List {
                    Button(action: {
                        settings.isContrastAdjusting.toggle()
                    }) {
                        HStack {
                            Text("螢幕對比度")
                                .foregroundColor(.black)
                            Spacer()
                            Image(systemName: settings.isContrastAdjusting ? "chevron.down" : "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if settings.isContrastAdjusting {
                        VStack {
                            Slider(value: $settings.screenContrast, in: 0...100, step: 1)
                            Text("當前對比度: \(Int(settings.screenContrast))")
                                .foregroundColor(.black)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .padding()
        }
        .navigationBarTitle("設定", displayMode: .inline)
    }
}

struct ContentView: View {
    @State private var captureSession = AVCaptureSession()
    @State private var model: VNCoreMLModel?
    @State private var backgroundImage: Image?
    @EnvironmentObject var settings: GlobalSettings

    var body: some View {
        ZStack {
            if let backgroundImage = backgroundImage {
                backgroundImage
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .brightness((settings.screenContrast - 50) / 100)
            } else {
                Color.gray
                    .edgesIgnoringSafeArea(.all)
                    .brightness((settings.screenContrast - 50) / 100)
            }

            CameraPreviewView(captureSession: $captureSession)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                Button(action: {
                    takePhoto()
                }) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.gray, lineWidth: 4)
                        )
                        .shadow(radius: 10)
                }
                .padding(.bottom, 40) // 修正 padding 調用
            }
        }
        .onAppear {
            setupCamera()
            setupModel()
        }
    }

    func setupCamera() {
        print("Initializing camera...")
        captureSession.sessionPreset = .vga640x480

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("Error: No video capture device available.")
            return
        }

        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            print("Error: Unable to create video input.")
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
            print("Video input added.")
        } else {
            print("Error: Unable to add video input.")
            return
        }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.setSampleBufferDelegate(CameraDelegate { pixelBuffer in
            self.processBuffer(pixelBuffer)
        }, queue: DispatchQueue(label: "videoQueue"))

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            print("Video output added.")
        } else {
            print("Error: Unable to add video output.")
            return
        }

        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
            print("Capture session started.")
        }
    }

    func setupModel() {
        do {
            let mlModel = try EmotionClassifier(configuration: MLModelConfiguration()).model
            model = try VNCoreMLModel(for: mlModel)
            print("Model loaded successfully.")
        } catch {
            fatalError("Error loading ML model: \(error)")
        }
    }

    func processBuffer(_ pixelBuffer: CVPixelBuffer) {
        guard let model = model else { return }

        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation], let firstResult = results.first else { return }

            DispatchQueue.main.async {
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
            backgroundImage = nil // 默認背景色
        }
    }

    func takePhoto() {
        print("Photo taken!")// T0D0: 可以在這新增拍照功能
    }
}


struct CameraPreviewView: UIViewControllerRepresentable {
    @Binding var captureSession: AVCaptureSession
    
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
            guard let previewLayer = previewLayer, let captureSession = captureSession else { return }
            previewLayer.session = captureSession
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

class CameraDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let processBuffer: (CVPixelBuffer) -> Void
    
    init(processBuffer: @escaping (CVPixelBuffer) -> Void) {
        self.processBuffer = processBuffer
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        processBuffer(pixelBuffer)
    }
}

@main
struct FaceCameraApp: App {
    @StateObject var settings = GlobalSettings() // 使用 @StateObject 修飾符將 GlobalSettings 作為全局狀態管理對象
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(settings) // 將GlobalSettinfs傳遞給所有子視圖
        }
    }
}

