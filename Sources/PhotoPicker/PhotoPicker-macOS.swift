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

#if os(macOS)
import SwiftUI

public extension View {
    /// Presents a system interface for allowing the user to import an existing
    /// photo.
    ///
    /// In order for the interface to appear, `isPresented` must be `true`. When
    /// the operation is finished, `isPresented` will be set to `false` before
    /// `onCompletion` is called. If the user cancels the operation,
    /// `isPresented` will be set to `false` and `onCompletion` will not be
    /// called.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to whether the interface should be shown.
    ///   - onCompletion: A callback that will be invoked when the operation has
    ///     succeeded or failed.
    ///   - result: A `Result` indicating whether the operation succeeded or
    ///     failed.
    func photoImporter(
        isPresented: Binding<Bool>,
        onCompletion: @escaping (Result<URL, Error>) -> Void
    ) -> some View {
        self.fileImporter(isPresented: isPresented,
                          allowedContentTypes: [.image],
                          onCompletion: onCompletion)
    }
    
    /// Presents a system interface for allowing the user to import multiple
    /// photos.
    ///
    /// In order for the interface to appear, `isPresented` must be `true`. When
    /// the operation is finished, `isPresented` will be set to `false` before
    /// `onCompletion` is called. If the user cancels the operation,
    /// `isPresented` will be set to `false` and `onCompletion` will not be
    /// called.
    ///
    /// - Note: Changing `allowsMultipleSelection`
    ///   while the file importer is presented will have no immediate effect,
    ///   however will apply the next time it is presented.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to whether the interface should be shown.
    ///   - allowsMultipleSelection: Whether the importer allows the user to
    ///     select more than one file to import.
    ///   - onCompletion: A callback that will be invoked when the operation has
    ///     succeeded or failed.
    ///   - result: A `Result` indicating whether the operation succeeded or
    ///     failed.
    func photoImporter(
        isPresented: Binding<Bool>,
        allowsMultipleSelection: Bool,
        onCompletion: @escaping (Result<[URL], Error>) -> Void
    ) -> some View {
        self.fileImporter(isPresented: isPresented,
                          allowedContentTypes: [.image],
                          allowsMultipleSelection: allowsMultipleSelection,
                          onCompletion: onCompletion)
    }
}

struct PhotoPicker_Previews: PreviewProvider {
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
        .photoImporter(isPresented: $showImagePicker) { result in
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
