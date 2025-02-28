//
//  ImageSaver.swift
//  Image-Temperature
//
//  Created by cleanmac on 28/02/25.
//

import UIKit

final class ImageSaver {}

// MARK: - Public methods

extension ImageSaver {
    func writeImageToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}
