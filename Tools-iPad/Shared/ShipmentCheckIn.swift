//
//  ShipmentCheckIn.swift
//  Pullscription Tools
//
//  Created by Jago Lourenco-Goddard on 2/22/25.
//

import SwiftUI

struct ShipmentCheckIn: View {
    @State private var selectedFileURL: URL?
    @State private var selectedFiles: [URL] = []
    
    var body: some View {
        Text("Shipment Check-In")
        if selectedFiles.isEmpty {
            Text("No files selected")
                .foregroundColor(.gray)
        } else {
            List(selectedFiles, id: \.self) { file in
                HStack {
                    Image(systemName: "doc")
                    Text(file.lastPathComponent)
                }
            }
            .frame(height: 200)
        }
        Button("Select Files") {
#if os(iOS)
            showFilePicker()
            #endif
        }
        .buttonStyle(.borderedProminent)
        VStack{
            Text("Weeks")

            HStack{
                Button("New Week") {
#if os(iOS)
                    showFilePicker()
                    #endif
                }
                .buttonStyle(.borderedProminent)
                Button("Delete Week") {
#if os(iOS)
                    showFilePicker()
                    #endif
                }
                .buttonStyle(.borderedProminent)
            }
        }
        
    }
    #if os(iOS)
    private func showFilePicker() {
        let picker = FilePicker { url in
            self.selectedFileURL = url
        }
        let controller = UIHostingController(rootView: picker)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(controller, animated: true)
        }
    }
    #endif
}

#Preview {
    ShipmentCheckIn()
}
