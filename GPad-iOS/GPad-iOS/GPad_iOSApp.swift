//
//  GPad_iOSApp.swift
//  GPad-iOS
//
//  Created by Gokul Nair on 19/03/26.
//

import SwiftUI

@main
struct GPad_iOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    UIApplication.shared.isIdleTimerDisabled = true
                }
        }
    }
}
