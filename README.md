# SwiftUI Media Picker

iOS/macOS media picker for importing images and videos in SwiftUI.

## Adding SwiftUI Media Picker as a Dependency

1. If you are using Xcode and have a minimum deployment target of iOS 14/macOS 11, make sure you are using Xcode 13.2 or later
2. Add the following line to the Package's `dependencies` array in your `Package.swift` file:

```swift
.package(url: "https://github.com/UWAppDev/SwiftUI-MediaPicker", from: "0.2.0"),
```

3. Include this library as a dependency for your executable target:

```swift
.target(name: "<target>", dependencies: [
    .product(name: "MediaPicker", package: "swiftui-mediapicker"),
]),
```

4. Add `import MediaPicker` to your source code.

## Example

```swift
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
```
