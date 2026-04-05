//
//  GPad_MacOSApp.swift
//  GPad-MacOS
//
//  Created by Gokul Nair on 19/03/26.
//

import SwiftUI

@main
struct GPad_MacOSApp: App {
    @State private var manager = MultipeerManager()
    @State private var panelController: FloatingPanelController?

    var body: some Scene {
        WindowGroup {
            ContentView(manager: manager)
                .onAppear {
                    KeySimulator.requestAccessibilityPermission()
                    manager.start()
                    let controller = FloatingPanelController(manager: manager)
                    controller.show()
                    panelController = controller
                }
        }
        .windowResizability(.contentSize)
    }
}
