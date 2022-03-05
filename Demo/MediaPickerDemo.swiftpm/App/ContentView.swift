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
import AVKit
import MediaPicker

struct ContentView: View {
    @State var urls: [URL] = []
    @State var isShowingMediaPicker = false
    
    var selectButton: some View {
        Button("Select Media") {
            isShowingMediaPicker = true
        }
        .mediaImporter(isPresented: $isShowingMediaPicker,
                       allowedMediaTypes: .all,
                       allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                self.urls = urls
            case .failure(let error):
                print(error)
                self.urls = []
            }
        }
    }
    
    var body: some View {
        List {
            Section {
                ForEach(urls, id: \.absoluteString) { url in
                    switch try! url.resourceValues(forKeys: [.contentTypeKey]).contentType! {
                    case let contentType where contentType.conforms(to: .image):
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                    case let contentType where contentType.conforms(to: .audiovisualContent):
                        VideoPlayer(player: AVPlayer(url: url))
                            .scaledToFit()
                    default:
                        Text("Can't display \(url.lastPathComponent)")
                    }
                }
            } header: {
                selectButton
            }
        }
    }
}
