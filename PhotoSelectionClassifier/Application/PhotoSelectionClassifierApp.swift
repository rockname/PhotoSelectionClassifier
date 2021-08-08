import SwiftUI
import Photos

@main
struct PhotoSelectionClassifierApp: App {
    @Environment(\.scenePhase) private var scenePhase

    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            AlbumView(viewModel: AlbumViewModel())
                .onAppear {
                    PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in }
                }
                .onChange(of: scenePhase) { phase in
                    switch phase {
                    case .active, .inactive: break
                    case .background: persistenceController.saveContext()
                    @unknown default: fatalError()
                    }
                }
        }
    }
}
