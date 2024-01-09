//
//  AboutView.swift
//  RadialMenu
//
//  Created by Ricky Yoshioka on 1/8/24.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack {
            Image("AppIconAsset")
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10.0, height: 10.0)))
                .frame(width: 100, height: 100)
            Text("Radial Menu")
                .font(.largeTitle)
            Text("Version 1.0.0")
                .foregroundColor(.gray)
            Text("© 2024 Richard Yoshioka")
                .foregroundColor(.gray)
            Button(action: openGithubLink) {
                Text("Link to my GitHub ")
                    .foregroundColor(.blue)
            }
            
        }
        .padding()
        .frame(width: 300, height: 300)
    }
    
    func openGithubLink() {
        if let url = URL(string: "https://github.com/ricky-yosh") {
            NSWorkspace.shared.open(url)
        }
    }
}

#Preview {
    AboutView()
}
