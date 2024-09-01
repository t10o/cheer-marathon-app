import Flutter
import UIKit
import background_task

func registerPlugins(registry: FlutterPluginRegistry) -> () {
    if (!registry.hasPlugin("BackgroundLocatorPlugin")) {
        GeneratedPluginRegistrant.register(with: registry)
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    BackgroundTaskPlugin.onRegisterDispatchEngine = {
        GeneratedPluginRegistrant.register(with: BackgroundTaskPlugin.dispatchEngine)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
