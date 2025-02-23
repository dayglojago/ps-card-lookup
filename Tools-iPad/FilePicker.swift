//
//  FilePicker.swift
//  Pullscription Tools
//
//  Created by Jago Lourenco-Goddard on 2/22/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
struct FilePicker: UIViewControllerRepresentable {
    var onPicked: (URL) -> Void

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: FilePicker

        init(parent: FilePicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            for url in urls {
                parent.onPicked(url)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.item], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}
#endif
