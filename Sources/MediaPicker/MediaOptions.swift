//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftUI FoodTracker tutorial series
//
// Copyright (c) 2020-2021 AppDev@UW.edu and the SwiftUI PhotoPicker authors
// Licensed under MIT License
//
// See https://github.com/UWAppDev/SwiftUI-PhotoPicker/blob/main/LICENSE
// for license information
// See https://github.com/UWAppDev/SwiftUI-PhotoPicker/graphs/contributors
// for the list of SwiftUI PhotoPicker project authors
//
//===----------------------------------------------------------------------===//

public struct MediaTypeOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// Only Live Photos.
    public static let livePhotos = MediaTypeOptions(rawValue: 1 << 0)
    /// Images, including Live Photos.
    public static let images: MediaTypeOptions = [MediaTypeOptions(rawValue: 1 << 1), livePhotos]
    /// Only videos.
    public static let videos = MediaTypeOptions(rawValue: 1 << 2)
    
    /// All media types.
    public static let all: MediaTypeOptions = [.images, .videos]
}