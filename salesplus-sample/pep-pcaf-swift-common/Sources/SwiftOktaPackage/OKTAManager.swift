//
//  File.swift
//  
//
//  Created by infyuser on 31/08/22.
//

import OktaOidc
import OktaJWT
import OSLog

public class TokenManager {

    public static let shared = TokenManager()

    public var idToken: String?
    public var accessToken: String?
    public var refreshToken: String?
    public var gpId: String?
    public var userName: String?
    public var userEmailId: String?
    public var roles: [String] = []

    public var logText = ""
    
    public var activeStateManager: OktaOidcStateManager? {
        didSet {
            self.idToken = activeStateManager?.idToken
            self.refreshToken = activeStateManager?.refreshToken
            self.accessToken = activeStateManager?.accessToken
        }
    }

    public var isTokenRenewalInProgress: Bool = false

    public func configureSession(configs: [String: String], completion:@escaping (Bool) -> Void) {

        do {
            let oktaOidc = try OktaOidc(configuration: OktaOidcConfig(with: configs))
            let savedStateManager = OktaOidcStateManager.readFromSecureStorage(for: oktaOidc.configuration)
            
            if savedStateManager != nil {
                self.activeStateManager = savedStateManager
                
                if self.idToken == nil || self.accessToken == nil || self.refreshToken == nil {
                    appendLog(text: "All tokens are NIL")
                    renewTokens { renewTokensStatus in
                        TokenManager.shared.loadUserInfo()
                        completion(renewTokensStatus)
                    }
                } else {
                    // Token might be expired in Keychain
                    renewTokensIfNeeded { renewTokensStatus in
                        TokenManager.shared.loadUserInfo()
                        completion(renewTokensStatus)
                    }
                }
            }
            else {
                completion(false)
            }
        } catch let error {
            os_log("%@", error.localizedDescription)
            self.appendLog(text: "Error:\(error.localizedDescription)")
        }
    }
    
    public func validateTokens(configs: [String: String]) -> Bool {
        
        do {
            let oktaOidc = try OktaOidc(configuration: OktaOidcConfig(with: configs))
            let savedStateManager = OktaOidcStateManager.readFromSecureStorage(for: oktaOidc.configuration)
            
            if savedStateManager != nil {
                
                self.activeStateManager = savedStateManager
                if self.idToken == nil || self.accessToken == nil || self.refreshToken == nil {
                    appendLog(text: "All tokens are NIL")
                    return false
                }

                guard let idToken = idToken, let idTokenObject = OKTIDToken(idTokenString: idToken), let accessToken = accessToken, let accessTokenObject = OKTIDToken(idTokenString: accessToken) else {
                    appendLog(text: "Tokens are NIL")
                    return false
                }

                os_log("ID Token Expiration left : %f", idTokenObject.expiresAt.timeIntervalSinceNow)
                os_log("Access Token Expiration left: %f", accessTokenObject.expiresAt.timeIntervalSinceNow)

                appendLog(text: "ID Token Expiration left : \(idTokenObject.expiresAt.timeIntervalSinceNow))")
                appendLog(text: "Access Token Expiration left: \(accessTokenObject.expiresAt.timeIntervalSinceNow)")
                
                if idTokenObject.expiresAt.timeIntervalSinceNow <= 0 || accessTokenObject.expiresAt.timeIntervalSinceNow <= 0 {
                    return false
                } else {
                    loadUserInfo()
                    return true
                }
            }
            
        } catch let error {
            os_log("%@", error.localizedDescription)
            self.appendLog(text: "Error:\(error.localizedDescription)")
        }
        
        return false
    }

    public func renewTokensIfNeeded(completion:@escaping  (Bool) -> Void) {

        guard let _ = activeStateManager else {
            appendLog(text: "State Manager is Nil")
            return
        }

        guard let idToken = idToken, let idTokenObject = OKTIDToken(idTokenString: idToken), let accessToken = accessToken, let accessTokenObject = OKTIDToken(idTokenString: accessToken) else {
            appendLog(text: "Tokens are NIL")
            return
        }

        os_log("ID Token Expiration left : %f", idTokenObject.expiresAt.timeIntervalSinceNow)
        os_log("Access Token Expiration left: %f", accessTokenObject.expiresAt.timeIntervalSinceNow)

        appendLog(text: "ID Token Expiration left : \(idTokenObject.expiresAt.timeIntervalSinceNow))")
        appendLog(text: "Access Token Expiration left: \(accessTokenObject.expiresAt.timeIntervalSinceNow)")
        
        // Renew tokens before 30 mins of expiry time left
        let timeInteravalLeft: TimeInterval = 30*60
        if idTokenObject.expiresAt.timeIntervalSinceNow < timeInteravalLeft || accessTokenObject.expiresAt.timeIntervalSinceNow < timeInteravalLeft {
            renewTokens(completion: completion)
        } else {
            completion(true)
        }
    }

    public func renewTokens (completion: @escaping (Bool) -> Void) {
        
        os_log("Tokens Renewal is in progress .... ")
        appendLog(text: "Tokens Renewal is in progress .... ")

        isTokenRenewalInProgress = true
        activeStateManager?.renew(callback: {[weak self] stateManager, error in

            self?.isTokenRenewalInProgress = false

            if let error = error {
                os_log("%@", error.localizedDescription)
                self?.appendLog(text: "Error:\(error.localizedDescription)")
                completion(false)
            }
            if let stateManager = stateManager {
                stateManager.writeToSecureStorage()
                self?.idToken = stateManager.idToken
                self?.refreshToken = stateManager.refreshToken
                self?.accessToken = stateManager.accessToken
                os_log("Tokens refreshed successfully")
                self?.appendLog(text: "Tokens refreshed successfully")

                completion(true)

            }
        })
    }

    func loadUserInfo() {
        
        guard let accessToken = self.activeStateManager?.accessToken, let decodedAccessToken = try? OktaOidcStateManager.decodeJWT(accessToken) else {
            return
        }
        TokenManager.shared.configureUser(info: decodedAccessToken)
    }

    func configureUser(info: [String: Any]?) {
        let userName = info?["FirstName"] as? String ?? ""
        UserDefaults.standard.set(userName, forKey: "FirstName")
        TokenManager.shared.userName = userName
        
        let userLastName = info?["LastName"] as? String ?? ""
        UserDefaults.standard.set(userLastName, forKey: "LastName")

        let userEmailId = info?["email"] as? String ?? ""
        UserDefaults.standard.set(userEmailId, forKey: "userEmailId")
        TokenManager.shared.userEmailId = userEmailId

        let gpid = info?["gpid"] as? String ?? "0"
        UserDefaults.standard.set(gpid, forKey: "gpid")
        TokenManager.shared.gpId = gpid

        if let roles = info?["pepapphhnwebapproles"] as? [String] {
            TokenManager.shared.roles = roles
        }
        
        let roles = roles.joined(separator: ";")
        appendLog(text: "USER ROLES:\(roles)")
    }
}

extension TokenManager {
    
    private func appendLog(text: String) {
        logText.append("\n")
        logText.append(text)
    }
}
