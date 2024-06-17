//
//  Pullscription_Card_LookupApp.swift
//  Pullscription Card Lookup
//
//  Created by Jago Lourenco-Goddard on 6/13/24.
//

import SwiftUI
import Sparkle

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
