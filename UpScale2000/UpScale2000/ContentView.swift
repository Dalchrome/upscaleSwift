//
//  ContentView.swift
//  UpScale2000
//
//  Created by Jones on 29/03/2024.
//

import SwiftUI
import Foundation
import CoreGraphics


struct ContentView: View {
    @State private var selectedImage: NSImage? = nil
    @State private var theurl: URL? = nil
    
    @State private var width = 0
    @State private var height = 0
    
    @State private var newWidth = 512
    @State private var newHeight = 512
    
    var body: some View {
        HStack{
            VStack {
                HStack {
                    Button("Select Image") {
                        let picker = NSOpenPanel()
                        picker.allowsMultipleSelection = false
                        picker.canChooseDirectories = false
                        picker.allowedFileTypes = ["png"]
                        picker.message = "Select an image:"
                        
                        if picker.runModal() == .OK {
                            let url = picker.url!/* else { return }*/
                            selectedImage = NSImage(contentsOf: url)
                            print(url)
                            theurl = url
                            width = Int(selectedImage!.size.width)
                            height = Int(selectedImage!.size.height)
                        }
                    }
                    Spacer()
                }
                if let image = selectedImage {
                    HStack {
                        Text("Original Width: \(width), Original Height: \(height)")
                        Spacer()
                    }
                    HStack{
                        Text("New Width")
                        TextField("width", value: $newWidth, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .padding()
                        Spacer()
                    }
                    HStack{
                        Text("New Height")
                        TextField("height", value: $newHeight, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .padding()
                        Spacer()
                    }
                }
                Spacer()
            }
            
            if let image = selectedImage {
                let upscaler = ImageUpscaler()
                if let upscaledCGImage = upscaler?.upscaleImage(url: theurl!, toSize: CGSize(width: newWidth, height: newHeight)) {
                    let finalImage = upscaledCGImage
                    Image(nsImage: NSImage(cgImage: finalImage, size: NSZeroSize))
                }
            }
        }
    }
}
