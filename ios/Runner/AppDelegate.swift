import UIKit
import Flutter
import jitsi_meet_flutter_sdk

@main
@objc class AppDelegate: FlutterAppDelegate {

  private var hasRetriedJitsiRegistration = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GeneratedPluginRegistrant.register(with: self)

    DispatchQueue.main.async { [weak self] in
      self?.retryJitsiRegistrationIfNeeded()
    }

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    retryJitsiRegistrationIfNeeded()
  }

  private func retryJitsiRegistrationIfNeeded() {
    guard !hasRetriedJitsiRegistration else { return }

    let hasRootViewController = UIApplication.shared
      .connectedScenes
      .compactMap { ($0 as? UIWindowScene)?.keyWindow }
      .first?.rootViewController != nil

    guard hasRootViewController else { return }
    hasRetriedJitsiRegistration = true

    if let registrar = registrar(forPlugin: "JitsiMeetPlugin") {
      JitsiMeetPlugin.register(with: registrar)
    }
  }

}
