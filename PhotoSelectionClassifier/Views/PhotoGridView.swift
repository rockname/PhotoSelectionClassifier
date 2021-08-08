import SwiftUI
import Photos

struct PhotoGridView: View {
    private let gridSize: CGSize
    
    @StateObject private var viewModel: PhotoGridViewModel
    
    init(
        viewModel: PhotoGridViewModel,
        gridSize: CGSize
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.gridSize = gridSize
    }
    
    var body: some View {
        Group {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: gridSize.width,
                        height: gridSize.height
                    )
                    .overlay(
                        Image(
                            systemName: viewModel.isSelected
                            ? "checkmark.circle.fill"
                            : "circle"
                        )
                            .foregroundColor(
                                viewModel.isSelected
                                ? Color.blue
                                : Color.gray
                            ),
                        alignment: .topTrailing
                    )
                    .onTapGesture {
                        viewModel.onPhotoGridTapped()
                    }
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
