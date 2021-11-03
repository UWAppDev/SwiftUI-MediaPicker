//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftUI FoodTracker tutorial series
//
// Copyright (c) 2020-2021 AppDev@UW.edu and the SwiftUI MediaPicker authors
// Licensed under MIT License
//
// See https://github.com/UWAppDev/SwiftUI-MediaPicker/blob/main/LICENSE
// for license information
// See https://github.com/UWAppDev/SwiftUI-MediaPicker/graphs/contributors
// for the list of SwiftUI MediaPicker project authors
//
//===----------------------------------------------------------------------===//

#if os(macOS)
import SwiftUI
import UniformTypeIdentifiers

public extension View {
    /// Presents a system interface for allowing the user to import an existing
    /// media.
    ///
    /// In order for the interface to appear, `isPresented` must be `true`. When
    /// the operation is finished, `isPresented` will be set to `false` before
    /// `onCompletion` is called. If the user cancels the operation,
    /// `isPresented` will be set to `false` and `onCompletion` will not be
    /// called.
    ///
    /// - Note: Changing `allowedMediaTypes` while the file importer is
    ///   presented will have no immediate effect, however will apply the next
    ///   time it is presented.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to whether the interface should be shown.
    ///   - allowedMediaTypes: The list of supported media types which can
    ///     be imported.
    ///   - onCompletion: A callback that will be invoked when the operation has
    ///     succeeded or failed.
    ///   - result: A `Result` indicating whether the operation succeeded or
    ///     failed.
    func mediaImporter(
        isPresented: Binding<Bool>,
        allowedMediaTypes: MediaTypeOptions,
        onCompletion: @escaping (Result<URL, Error>) -> Void
    ) -> some View {
        self.fileImporter(isPresented: isPresented,
                          allowedContentTypes: .from(allowedMediaTypes),
                          onCompletion: onCompletion)
    }
    
    /// Presents a system interface for allowing the user to import multiple
    /// medium.
    ///
    /// In order for the interface to appear, `isPresented` must be `true`. When
    /// the operation is finished, `isPresented` will be set to `false` before
    /// `onCompletion` is called. If the user cancels the operation,
    /// `isPresented` will be set to `false` and `onCompletion` will not be
    /// called.
    ///
    /// - Note: Changing `allowedMediaTypes` or `allowsMultipleSelection`
    ///   while the file importer is presented will have no immediate effect,
    ///   however will apply the next time it is presented.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to whether the interface should be shown.
    ///   - allowedMediaTypes: The list of supported media types which can
    ///     be imported.
    ///   - allowsMultipleSelection: Whether the importer allows the user to
    ///     select more than one file to import.
    ///   - onCompletion: A callback that will be invoked when the operation has
    ///     succeeded or failed.
    ///   - result: A `Result` indicating whether the operation succeeded or
    ///     failed.
    func mediaImporter(
        isPresented: Binding<Bool>,
        allowedMediaTypes: MediaTypeOptions,
        allowsMultipleSelection: Bool,
        onCompletion: @escaping (Result<[URL], Error>) -> Void
    ) -> some View {
        self.fileImporter(isPresented: isPresented,
                          allowedContentTypes: .from(allowedMediaTypes),
                          allowsMultipleSelection: allowsMultipleSelection,
                          onCompletion: onCompletion)
    }
}

fileprivate extension Array where Element == UTType {
    static func from(_ mediaOptions: MediaTypeOptions) -> Self {
        var types = Self()
        if mediaOptions.contains(.images) {
            types.append(.image)
        } else if mediaOptions.contains(.livePhotos) {
            types.append(.livePhoto)
        }
        if mediaOptions.contains(.videos) {
            types.append(.audiovisualContent)
        }
        return types
    }
}

struct MediaPicker_Previews: PreviewProvider {
    @State
    static var showImagePicker: Bool = false
    
    @State
    static var url: URL? = nil
    
    static var previews: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                Button {
                    showImagePicker = true
                } label: {
                    Text("Select Image")
                }
                
                if let url = url {
                    if #available(macOS 12, *) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit()
                        } placeholder: {
                            EmptyView()
                        }
                    } else {
                        if let nsImage = NSImage(contentsOf: url) {
                            Image(nsImage: nsImage)
                        } else {
                            Text("Can't load contents of \(url)")
                        }
                    }
                }
                Spacer()
            }
            Spacer()
        }
        .mediaImporter(isPresented: $showImagePicker,
                       allowedMediaTypes: .images) { result in
            switch result {
            case .success(let url):
                self.url = url
            case .failure(let error):
                print(error)
                self.url = nil
            }
        }
    }
}
#endif
