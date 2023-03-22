//
//  GoToolHome.swift
//  module360
//
//  Created by Shrey Shrivastava on 06/03/23.
//

import SwiftUI

public struct GoToolHome: View {
    public var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, Go Tools App")
        }
        .padding()
    }
    
    public init() {
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        GoToolHome()
    }
}
