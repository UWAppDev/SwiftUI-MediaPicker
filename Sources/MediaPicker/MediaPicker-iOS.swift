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
import PhotosUI
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
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = allowsMultipleSelection ? 0 : 1
        configuration.filter = PHPickerFilter.from(allowedMediaTypes)

        return self.sheet(isPresented: isPresented) {
            MediaPicker(
                isPresented: isPresented,
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
            getImageURLs(from: results, then: complete)
        }
        
        // Explore structured concurrency in Swift
        // https://developer.apple.com/wwdc21/10134
        private func getImageURLs(from phPickerResults: [PHPickerResult],
                                  then resume: @escaping (Result<[URL], Error>) -> ()) {
            var imageURLs = [URL]()
            var resumed = false
            imageURLs.reserveCapacity(phPickerResults.count)
            let group = DispatchGroup()
            
            for result in phPickerResults {
                guard result.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else {
                    resumed = true
                    resume(.failure(AVError(.failedToLoadMediaData)))
                    return
                }
                group.enter()
                result.itemProvider.loadImageFileURL { result in
                    switch result {
                    case .success(let url):
                        imageURLs.append(url)
                    case .failure(let error):
                        resumed = true
                        resume(.failure(error))
                    }
                    group.leave()
                }
            }
            group.notify(queue: .global()) {
                if !resumed {
                    resumed = true
                    resume(.success(imageURLs))
                }
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
    func loadImageFileURL(then resume: @escaping (Result<URL, Error>) -> ()) {
        // https://developer.apple.com/forums/thread/652496
        loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
            guard let src = url else {
                return resume(.failure(error!))
            }
            do {
                // Because the src/url will be deleted once we return,
                // will copy the stored image to a different temp url.
                let dst = try FileManager.default.url(
                    for: .itemReplacementDirectory, in: .userDomainMask,
                    appropriateFor: src, create: true
                ).appendingPathComponent(src.lastPathComponent)
                if !FileManager.default.fileExists(atPath: dst.path) {
                    try FileManager.default.copyItem(at: src, to: dst)
                }
                resume(.success(dst))
            } catch {
                resume(.failure(error))
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
