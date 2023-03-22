//
//  ContentView.swift
//  Monoreposample
//
//  Created by Shrey Shrivastava on 06/03/23.
//

import SwiftUI
import SalesProPlusFramework
import GoToolsFramework

struct CockpitView: View {
    var body: some View {
        NavigationView{
            VStack{
                Text("Cockpit view")
                HStack {
                    NavigationLink(destination: ProPlusContentView()) {
                        VStack {
                            Image(systemName: "globe")
                                .imageScale(.large)
                                .foregroundColor(.accentColor)
                            Text("Sales Pro plus")
                        }
                        .padding()
                    }
                    
                    NavigationLink(destination: GoToolHome()) {
                        VStack {
                            Image(systemName: "globe")
                                .imageScale(.large)
                                .foregroundColor(.accentColor)
                            Text("Go tools")
                        }
                        .padding()
                    }
                }
            }
            
        }
    }
}


struct CockpitView_Previews: PreviewProvider {
    static var previews: some View {
        CockpitView()
    }
}
