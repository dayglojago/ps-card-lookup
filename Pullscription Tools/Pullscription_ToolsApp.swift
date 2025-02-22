//
//  Pullscription_Card_LookupApp.swift
//  Pullscription Card Lookup
//
//  Created by Jago Lourenco-Goddard on 6/13/24.
//
import AppKit
import SwiftUI
import Sparkle


/// Function to resize the macOS window
func resizeWindow(width: CGFloat, height: CGFloat) {
    DispatchQueue.main.async {
        if let window = NSApplication.shared.windows.first {
            let newSize = NSSize(width: width, height: height)
            window.setContentSize(newSize)
            //window.center() // Optionally re-center window
        }
    }
}

@main
struct Pullscription_Card_LookupApp: App {
    private let updaterController: SPUStandardUpdaterController

        init() {
            updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        }
    var body: some Scene {
        
        WindowGroup {
            MainAppView()
        }
        .commands {
                    CommandGroup(after: .appInfo) {
                        CheckForUpdatesView(updater: updaterController.updater)
                    }
                }
//        .commands {
//            CommandMenu("File") {
//                Button(action: {
//                    // Action for new file
//                }) {
//                    Text("New File")
//                }
//                Button(action: {
//                    // Action for open file
//                }) {
//                    Text("Open File")
//                }
//                Button(action: {
//                    // Action for save file
//                }) {
//                    Text("Save File")
//                }
//            }
//            CommandMenu("Edit") {
//                Button(action: {
//                    // Action for undo
//                }) {
//                    Text("Undo")
//                }
//                Button(action: {
//                    // Action for redo
//                }) {
//                    Text("Redo")
//                }
//            }
//        }
    }
}
