import SwiftUI

struct AlbumGridView: View {
    private let targetSize: CGSize
    
    @StateObject private var viewModel: AlbumGridViewModel
    
    init(
        viewModel: AlbumGridViewModel,
        targetSize: CGSize
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.targetSize = targetSize
    }
    
    var body: some View {
        Group {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: targetSize.width,
                        height: targetSize.height
                    )
            } else {
                ProgressView()
                    .onAppear {
                        Task {
                            await viewModel.onAppear()
                        }
                    }
            }
        }
    }
}
