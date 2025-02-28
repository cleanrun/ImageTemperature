//
//  ContentView.swift
//  Image-Temperature
//
//  Created by cleanmac on 27/02/25.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var temperatureValue: Double = 0
    @State private var photoItem: PhotosPickerItem?
    @State private var originalImage: UIImage?
    @State private var adjustedImage: UIImage?
    
    @State private var showSaveImageSuccessAlert: Bool = false
    @State private var showFailToLoadImageAlert: Bool = false
    
    private let temperatureManipulator = TemperatureManipulator()
    private let imageSaver = ImageSaver()
    
    var body: some View {
        VStack {
            ZStack {
                if adjustedImage != nil {
                    Image(uiImage: adjustedImage!)
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.2))
                .clipped()
                .cornerRadius(10)
            
            Spacer()
            
            Slider(value: $temperatureValue, in: -1...1, onEditingChanged: { _ in
                if let originalImage, let image = temperatureManipulator.adjustImageTemperature(image: originalImage, temperature: temperatureValue) {
                    adjustedImage = image
                }
            })
            
            HStack {
                PhotosPicker("Select Image", selection: $photoItem, matching: .images)
                    .frame(maxWidth: .infinity)
                
                Button(action: {
                    imageSaver.writeImageToPhotoAlbum(image: adjustedImage!)
                    showSaveImageSuccessAlert = true
                }, label: {
                    Text("Export Image")
                })
                .frame(maxWidth: .infinity)
                .disabled(photoItem == nil)
            }
        }
        .padding()
        .onChange(of: photoItem, {
            Task {
                if let loaded = try? await photoItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: loaded) {
                    let normalizedImage = temperatureManipulator.fixImageOrientation(uiImage)
                    
                    originalImage = normalizedImage
                    adjustedImage = normalizedImage
                } else {
                    showFailToLoadImageAlert = true
                }
            }
        })
        .alert("Image export", isPresented: $showSaveImageSuccessAlert, actions: {
            Button(action: {
                showSaveImageSuccessAlert = false
            }, label: {
                Text("OK")
            })
        }, message: {
            Text("Image exported successfully! Check your photos library.")
        })
        .alert("Load Image", isPresented: $showFailToLoadImageAlert, actions: {
            Button(action: {
                showFailToLoadImageAlert = false
            }, label: {
                Text("OK")
            })
        }, message: {
            Text("Unable to load image. Please try again.")
        })
    }
}

#Preview {
    ContentView()
}
