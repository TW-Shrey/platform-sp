//
//  PlusAppAuthViewModel.swift
//  modulePlus
//
//  Created by Shrey Shrivastava on 06/03/23.
//

import Foundation
import pcaf_mbl_cb
import SwiftOktaPackage

class PlusAppAuthViewModel {
    let cbManager: CouchbaseManager
    
    init(cbManager: CouchbaseManager) {
        let authManager = AuthManager()
        self.cbManager = CouchbaseManager.init(authManager: authManager)
    }
    
    func getAccounts() -> [String]{
        return self.cbManager.getAccounts()
    }
    
}
