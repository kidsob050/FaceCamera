//
//  ContentView.swift
//  FaceCamera
//
//  Created by user on 12/2/24.
//

import SwiftUI

@available(iOS 13.0, *)
struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    @available(iOS 13.0, *)
    static var previews: some View {
        ContentView()
    }
}
