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

#if os(iOS)
import SwiftUI
@_implementationOnly import PhotosUI

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
    /// - Note: Changing `allowedMediaTypes` while the media importer is
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
        self.mediaImporter(isPresented: isPresented,
                           allowedMediaTypes: allowedMediaTypes,
                           allowsMultipleSelection: false) { result in
            onCompletion(result.map { $0.first! })
        }
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
    ///   while the media importer is presented will have no immediate effect,
    ///   however will apply the next time it is presented.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to whether the interface should be shown.
    ///   - allowedMediaTypes: The list of supported media types which can
    ///     be imported.
    ///   - allowsMultipleSelection: Whether the importer allows the user to
    ///     select more than one media to import.
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
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = allowsMultipleSelection ? 0 : 1
        configuration.filter = PHPickerFilter.from(allowedMediaTypes)

        return self.sheet(isPresented: isPresented) {
            MediaPicker(
                isPresented: isPresented,
                allowedContentTypes: allowedMediaTypes.typeIdentifiers,
                configuration: configuration,
                onCompletion: onCompletion
            )
        }
    }
}

fileprivate extension PHPickerFilter {
    static func from(_ mediaOptions: MediaTypeOptions) -> Self {
        var filters = [PHPickerFilter]()
        if mediaOptions.contains(.images) {
            filters.append(.images)
        } else if mediaOptions.contains(.livePhotos) {
            filters.append(.livePhotos)
        }
        if mediaOptions.contains(.videos) {
            filters.append(.videos)
        }
        return PHPickerFilter.any(of: filters)
    }
}

// Meet the new Photos picker
// https://developer.apple.com/wwdc20/10652
fileprivate struct MediaPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let allowedContentTypes: [UTType]
    let configuration: PHPickerConfiguration
    let onCompletion: (Result<[URL], Error>) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController,
                                context: Context) {
        // do nothing
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(for: self)
    }
    
    class Coordinator: PHPickerViewControllerDelegate {
        let coordinated: MediaPicker
        
        init(for picker: MediaPicker) {
            self.coordinated = picker
        }
        
        func picker(_ picker: PHPickerViewController,
                    didFinishPicking results: [PHPickerResult]) {
            guard !results.isEmpty else {
                dismiss()
                return
            }
            Task {
                do {
                    let images = try await imageURLs(from: results)
                    complete(with: .success(images))
                } catch {
                    complete(with: .failure(error))
                }
            }
        }
        
        // Explore structured concurrency in Swift
        // https://developer.apple.com/wwdc21/10134
        private func imageURLs(from phPickerResults: [PHPickerResult]) async throws -> [URL] {
            try await withThrowingTaskGroup(of: URL.self) { group in
                var imageURLs = [URL]()
                imageURLs.reserveCapacity(phPickerResults.count)
                
            pickerResultsLoop:
                for result in phPickerResults {
                    let provider = result.itemProvider
                    // TOOD: investigate should we instead use/consider
                    // provider.registeredTypeIdentifiers
                    for type in coordinated.allowedContentTypes {
                        if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                            group.addTask {
                                try await provider.fileURL(for: type)
                            }
                            continue pickerResultsLoop
                        }
                    }
                    throw AVError(.failedToLoadMediaData)
                }
                
                // Obtain results from the child tasks, sequentially.
                for try await imageURL in group {
                    imageURLs.append(imageURL)
                }
                return imageURLs
            }
        }
        
        private func dismiss() {
            coordinated.isPresented = false
        }
        
        private func complete(with result: Result<[URL], Error>) {
            dismiss()
            coordinated.onCompletion(result)
        }
    }
}

fileprivate extension NSItemProvider {
    // Meet async/await in Swift
    // https://developer.apple.com/wwdc21/10132/
    func fileURL(for type: UTType) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            // https://developer.apple.com/forums/thread/652496
            loadFileRepresentation(forTypeIdentifier: type.identifier) { url, error in
                guard let src = url else {
                    return continuation.resume(throwing: error!)
                }
                do {
                    // Because the src/url will be deleted once we return,
                    // will copy the stored image to a different temp url.
                    let dst = FileManager.default.temporaryDirectory
                        .appendingPathComponent(src.lastPathComponent)
                    if !FileManager.default.fileExists(atPath: dst.path) {
                        try FileManager.default.copyItem(at: src, to: dst)
                    }
                    continuation.resume(returning: dst)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

struct MediaPicker_Previews: PreviewProvider {
    @State
    static var showImagePicker: Bool = false
    @State
    static var url: URL? = nil
    
    static var previews: some View {
        VStack {
            Button {
                showImagePicker = true
            } label: {
                Text("Select Image")
            }
            
            if let url = url {
                if #available(iOS 15, *) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        EmptyView()
                    }
                } else {
                    if let data = try? Data(contentsOf: url),
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                    } else {
                        Text("Can't load contents of \(url)")
                    }
                }
            }
        }
        .mediaImporter(isPresented: $showImagePicker,
                       allowedMediaTypes: .images) { result in
            switch result {
            case .success(let url):
                self.url = url
            case .failure(let error):
                print(error)
                url = nil
            }
        }
    }
}
#endif
