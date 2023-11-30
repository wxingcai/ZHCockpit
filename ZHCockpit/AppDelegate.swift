//
//  AppDelegate.swift
//  ScreenShield
//
//  Created by apple on 2023/11/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var shouldRotate = false
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.backgroundColor = UIColor.clear
        self.window?.makeKeyAndVisible()
        
//        let navVC = UINavigationController.init(rootViewController: )
        self.window?.rootViewController = ViewController()
        return true
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if shouldRotate {
            return .all
        } else {
            return .portrait
        }
    }
}

