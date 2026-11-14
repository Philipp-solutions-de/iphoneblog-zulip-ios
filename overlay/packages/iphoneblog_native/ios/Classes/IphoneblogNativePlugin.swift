import AuthenticationServices
import Flutter
import UIKit
import UserNotifications

/// APNs registration and web sign-in for the iphoneblog build.
/// Talks to Apple only; no Firebase, no Google service.
public class IphoneblogNativePlugin: NSObject, FlutterPlugin,
    ASWebAuthenticationPresentationContextProviding {
  private var tokenWaiters: [FlutterResult] = []
  private var lastToken: String?
  private var authSession: ASWebAuthenticationSession?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "de.iphoneblog/native", binaryMessenger: registrar.messenger())
    let instance = IphoneblogNativePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestNotificationPermission":
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
        _, _ in
        UNUserNotificationCenter.current().getNotificationSettings { settings in
          let status: String
          switch settings.authorizationStatus {
          case .authorized, .ephemeral: status = "authorized"
          case .provisional: status = "provisional"
          case .denied: status = "denied"
          default: status = "notDetermined"
          }
          DispatchQueue.main.async { result(status) }
        }
      }
    case "apnsToken":
      if let token = lastToken {
        result(token)
        return
      }
      tokenWaiters.append(result)
      UIApplication.shared.registerForRemoteNotifications()
    case "webAuth":
      guard let args = call.arguments as? [String: Any],
        let urlString = args["url"] as? String, let url = URL(string: urlString),
        let scheme = args["callbackScheme"] as? String
      else {
        result(FlutterError(code: "bad-args", message: nil, details: nil))
        return
      }
      startWebAuth(url: url, scheme: scheme, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func startWebAuth(url: URL, scheme: String, result: @escaping FlutterResult) {
    let session = ASWebAuthenticationSession(url: url, callbackURLScheme: scheme) {
      [weak self] callbackURL, error in
      self?.authSession = nil
      if let callbackURL = callbackURL {
        result(callbackURL.absoluteString)
      } else if let error = error as? ASWebAuthenticationSessionError,
        error.code == .canceledLogin
      {
        result(FlutterError(code: "canceled", message: nil, details: nil))
      } else {
        result(FlutterError(code: "failed", message: error?.localizedDescription, details: nil))
      }
    }
    session.presentationContextProvider = self
    // Keep Safari's cookies, so a second sign-in through WordPress is one tap.
    session.prefersEphemeralWebBrowserSession = false
    authSession = session
    if !session.start() {
      authSession = nil
      result(FlutterError(code: "failed", message: "Could not open the sign-in sheet.", details: nil))
    }
  }

  public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    return scenes.flatMap { $0.windows }.first { $0.isKeyWindow } ?? ASPresentationAnchor()
  }

  // MARK: UIApplicationDelegate, forwarded by Flutter

  public func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    lastToken = token
    finishTokenWaiters(token)
  }

  public func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    finishTokenWaiters(nil)
  }

  private func finishTokenWaiters(_ token: String?) {
    let waiters = tokenWaiters
    tokenWaiters = []
    for waiter in waiters { waiter(token) }
  }
}
