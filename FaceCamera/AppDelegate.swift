//
//  AppDelegate.swift
//  FaceCamera
//
//  Created by user on 12/2/24.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // 设置初始视图控制器
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = ViewController() // 使用你的自定义 ViewController
        window?.makeKeyAndVisible()
        return true
    }
}
