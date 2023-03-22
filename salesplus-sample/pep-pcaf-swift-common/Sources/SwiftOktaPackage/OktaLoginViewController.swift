//
//  OktaLoginViewController.swift
//  PepAuthKitExample
//
//  Modified by Mirold on 9/05/22.
//
// swiftlint:disable line_length
import UIKit
import OktaOidc
import OktaJWT
import SwiftUI
import OSLog

public protocol OktaLoginViewControllerPotocol {
    func didFinishLogin(viewController: OktaLoginViewController?, loginStatus: LoginStatus, stateManager: OktaOidcStateManager?)
}

public enum LoginStatus {
    case unknown, success, failure

    public init?(index: Int) {
        switch index {
        case 0: self = .unknown
        case 1: self = .success
        case 2: self = .failure
        default: return nil
        }
    }
}

public class Coordinator: NSObject, OktaLoginViewControllerPotocol {

    public var parent: OktaLoginView

    public init(_ parent: OktaLoginView) {
        self.parent = parent
    }

    // OktaLoginViewControllerPotocol 
    public func didFinishLogin(viewController: OktaLoginViewController?, loginStatus: LoginStatus, stateManager: OktaOidcStateManager?) {
        viewController?.dismiss(animated: true)
        self.parent.loginStatus = loginStatus
    }
}

public typealias UIViewControllerType = OktaLoginViewController

public struct OktaLoginView: UIViewControllerRepresentable {

    @Binding var loginStatus: LoginStatus?
    var configs: [String: String]

    public init(loginStatus: Binding<LoginStatus?> = .constant(.unknown), configs: [String: String]) {
        _loginStatus = loginStatus
        self.configs = configs

    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    public func makeUIViewController(context: Context) -> OktaLoginViewController {
        let loginVC = OktaLoginViewController()
        loginVC.oktaLoginDelegate = context.coordinator
        loginVC.configs = context.coordinator.parent.configs
        return loginVC
    }

    public func updateUIViewController(_ uiViewController: OktaLoginViewController, context: Context) {

    }
}

public class OktaLoginViewController: UIViewController {

    private var oktaOidc: OktaOidc?
    private var stateManager: OktaOidcStateManager?
    public var oktaLoginDelegate: OktaLoginViewControllerPotocol?
    private var logger = Log()
    var configs: [String: String] = [:]

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.backgroundColor = .lightGray
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        self.view.backgroundColor = .red
        do {
            // let oktaConfigs = try? OktaOidcConfig(with: configs ?? [:])
            oktaOidc = try OktaOidc(configuration: OktaOidcConfig(with: configs))
            oktaOidc?.configuration.requestCustomizationDelegate = self

        } catch let error {
            DispatchQueue.main.async {
                self.showAlert(title: "Error", message: error.localizedDescription)
            }
            return
        }

        guard let _ = oktaOidc else {
            self.oktaLoginDelegate?.didFinishLogin(viewController: self, loginStatus: .failure, stateManager: nil)
            return
        }

        signInWithBrowser()
    }

    private  func signInWithBrowser() {

        oktaOidc?.signInWithBrowser(from: self, callback: { [weak self] oktaStateManager, error in

            if let error = error {
                self?.showAlert(title: "Error", message: error.localizedDescription)
                self?.oktaLoginDelegate?.didFinishLogin(viewController: self, loginStatus: .failure, stateManager: nil)
                return
            }

            // Remove any previous session
            do {
                try self?.stateManager?.removeFromSecureStorage()
            } catch let error {
                self?.showAlert(title: "Error", message: error.localizedDescription)
            }

            // Save sesstion manager in keychain
            self?.stateManager = oktaStateManager
            self?.stateManager?.writeToSecureStorage()

            // Very Less likey case of not having tokens on first time login
            if self?.stateManager?.idToken == nil || self?.stateManager?.accessToken == nil || self?.stateManager?.refreshToken == nil {
                self?.oktaLoginDelegate?.didFinishLogin(viewController: self, loginStatus: .failure, stateManager: nil)
                return
            }

            // Set tokens in Token Manager
            TokenManager.shared.activeStateManager = self?.stateManager
            TokenManager.shared.loadUserInfo()
        
            let loginStatus: LoginStatus =  .success
            self?.oktaLoginDelegate?.didFinishLogin(viewController: self, loginStatus: loginStatus, stateManager: nil)

            DispatchQueue.global().async {
                let options = ["iss": self?.oktaOidc?.configuration.issuer, "exp": "true"]
              let idTokenValidator = OktaJWTValidator(options)
                do {
                    _ = try idTokenValidator.isValid(self?.stateManager!.idToken ?? "0")
                } catch let verificationError {
                    var errorDescription = verificationError.localizedDescription
                    if let verificationError = verificationError as? OktaJWTVerificationError, let description = verificationError.errorDescription {
                        errorDescription = description
                    }
                    DispatchQueue.main.async {
                        self?.showAlert(title: "Error", message: errorDescription)
                    }
                }
            }
        })
    }
}

private extension OktaLoginViewController {

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension OktaLoginViewController: OktaNetworkRequestCustomizationDelegate {

    public func customizableURLRequest(_ request: URLRequest?) -> URLRequest? {
#if DEBUG
        print(#file, #function, request?.url ?? "something went wrong", to: &logger)
#endif
        return request
    }

    public func didReceive(_ response: URLResponse?) {
        guard let response = response else {
            return
        }
#if DEBUG
        print("Okta OIDC network response: \(response)", to: &logger)
#endif
    }

}
