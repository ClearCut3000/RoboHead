//
//  AppDelegate.swift
//  RoboHead
//
//  Created by Николай Никитин on 20.10.2021.
//

import UIKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?


  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    // Create the SwiftUI view that provides the window contents.
    let contentView = ContentView()

    // Use a UIHostingController as window root view controller.
    let window = UIWindow(frame: UIScreen.main.bounds)
    window.rootViewController = UIHostingController(rootView: contentView)
    self.window = window
    window.makeKeyAndVisible()
    return true
  }
}
