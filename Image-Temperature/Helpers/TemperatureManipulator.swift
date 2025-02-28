//
//  TemperatureManipulator.swift
//  Image-Temperature
//
//  Created by cleanmac on 27/02/25.
//

import UIKit
import opencv2

final class TemperatureManipulator {}

// MARK: - Public methods

extension TemperatureManipulator {
    func fixImageOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? image
    }
    
    func adjustImageTemperature(image: UIImage, temperature: Double) -> UIImage? {
        // Converts the UIImage to Mat so OpenCV can process it
        var uiImageToMat = uiImageToMat(image: image)
        
        var channels: [Mat] = []
        // Splits the image into its 3 color channels (BGR), so we can individually manipulate each color channel
        // [0] is Blue, [1] is Green, and [2] is Red
        Core.split(m: uiImageToMat, mv: &channels)
        
        if temperature > 0 { // Make the image warmer
            // Decreases blue channel
            Core.multiply(src1: channels[0], srcScalar: Scalar(1.0 - temperature), dst: channels[0])
            // Increases red channel
            Core.multiply(src1: channels[2], srcScalar: Scalar(1.0 + temperature), dst: channels[2])
        } else { // Make the image cooler
            // Increases the blue channel
            Core.multiply(src1: channels[0], srcScalar: Scalar(1.0 + abs(temperature)), dst: channels[0])
            // Decreases the red channel
            Core.multiply(src1: channels[2], srcScalar: Scalar(1.0 - abs(temperature)), dst: channels[2])
        }
        
        // Merges the split channels into a single mat for UIImage conversion
        Core.merge(mv: channels, dst: uiImageToMat)
        
        // If the Mat has only 3 channels (BGR), we need to convert the color space into BGRA because iOS will need the alpha channel for RGBA color space
        if uiImageToMat.channels() == 3 {
            let bgraMat = Mat()
            Imgproc.cvtColor(src: uiImageToMat, dst: bgraMat, code: .COLOR_BGR2BGRA)
            uiImageToMat = bgraMat
        }
        
        return convertMatToUIImage(from: uiImageToMat)
    }
}

// MARK: - Private methods

private extension TemperatureManipulator {
    func uiImageToMat(image: UIImage) -> Mat {
        // Converts a UIImage instance into an OpenCV Mat
        // Automatically extracts pixel data and stores it as an OpenCV Mat
        let mat = Mat(uiImage: image)
        // An empty Mat that will store the converted image
        let matConverted = Mat()
        
        // This method converts images between different color spaces
        // UIImage uses RGBA color format while OpenCV prefers BGR, and we need to convert it
        // otherwise the colors would be incorrect (red would become blue, etc).
        Imgproc.cvtColor(src: mat, dst: matConverted, code: .COLOR_RGBA2BGR)
        
        return matConverted
    }
    
    func convertMatToUIImage(from mat: Mat) -> UIImage? {
        // Checks whether the Mat is empty
        guard !mat.empty() else {
            print("\(#function); Mat is empty")
            return nil
        }
        
        // Prepares the RGB color space, since iOS uses RGBA
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        // RGBA or BGRA uses 4 bytes per pixel
        let bytesPerPixel = 4
        // The total number of bytes per row in the image
        let bytesPerRow = Int(mat.cols()) * bytesPerPixel
        // Each color channel (red, green, blue) uses 8 bits
        let bitsPerComponent = 8
        // Each pixel uses 4 channels (RGBA or BGRA), multiple it with each component: 4 * 8 = 32 bits
        let bitsPerPixel = bytesPerPixel * bitsPerComponent
        
        // mat.total() gets the total number of pixels in the image
        // mat.elemSize() gets the number of bytes per pixel (RGBA or BGRA has 4 bytes)
        let dataSize = mat.total() * mat.elemSize()
        // Creates a Data object by copying from the Mat's data pointer
        let copiedData = Data(bytes: mat.dataPointer(), count: dataSize)
        
        // This object wraps the pixel data so it can be used to create a CGImage from the copied data
        let provider = CGDataProvider(data: copiedData as CFData)
        
        guard let cgImage = CGImage(
            width: Int(mat.cols()),
            height: Int(mat.rows()),
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            // Means the image will have RGB channels, and we skip the Alpha value (RGBA means red, green, blue, alpha which iOS and UIImage uses)
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
            provider: provider!,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else {
            print("\(#function); Failed to create CGImage")
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}
