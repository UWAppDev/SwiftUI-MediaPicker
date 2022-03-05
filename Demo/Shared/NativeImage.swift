//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftUI FoodTracker tutorial series
//
// Copyright (c) 2020-2022 AppDev@UW.edu and the SwiftUI MediaPicker authors
// Licensed under MIT License
//
// See https://github.com/UWAppDev/SwiftUI-MediaPicker/blob/main/LICENSE
// for license information
// See https://github.com/UWAppDev/SwiftUI-MediaPicker/graphs/contributors
// for the list of SwiftUI MediaPicker project authors
//
//===----------------------------------------------------------------------===//

import SwiftUI

#if canImport(UIKit)
import UIKit

typealias NativeImage = UIImage

extension Image {
    init(nativeImage: NativeImage) {
        self.init(uiImage: nativeImage)
    }
}
#else
import AppKit

typealias NativeImage = NSImage

extension Image {
    init(nativeImage: NativeImage) {
        self.init(nsImage: nativeImage)
    }
}
#endif
