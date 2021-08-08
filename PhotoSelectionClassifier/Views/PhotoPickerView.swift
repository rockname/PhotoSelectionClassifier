import SwiftUI

struct PhotoPickerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: PhotoPickerViewModel

    init(viewModel: PhotoPickerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            VStack {
                PhotoCollectionView(photoGridViewModels: $viewModel.photoGridViewModels)
                Spacer()
                ShareButton {
                    Task {
                        await viewModel.onShareButtonTapped()
                    }
                }
            }
            .navigationBarItems(
                leading: Button(action: {
                    viewModel.onCloseButtonTapped()
                }) {
                    Image(systemName: "xmark")
                },
                trailing: Group {
                    if viewModel.showsAutoSelectButton {
                        Button(action: {
                            Task {
                                await viewModel.onAutoSelectButtonTapped()
                            }
                        }) {
                            Text("Auto select")
                        }
                    } else {
                        EmptyView()
                    }
                }
            )
            .navigationTitle("Choose photos")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            Task {
                await viewModel.onAppear()
            }
        }
        .onReceive(viewModel.$shouldDismiss) { shouldDismiss in
            if shouldDismiss { dismiss() }
        }
    }
}

private struct PhotoCollectionView: View {
    private let gridItemLayout = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    @Binding var photoGridViewModels: [PhotoGridViewModel]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridItemLayout) {
                ForEach(photoGridViewModels) { viewModel in
                    GeometryReader { proxy in
                        PhotoGridView(
                            viewModel: viewModel,
                            gridSize: CGSize(
                                width: proxy.size.width,
                                height: proxy.size.width
                            )
                        )
                    }
                    .clipped()
                    .aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }
}

private struct ShareButton: View {
    var onTapped: (() -> Void)

    var body: some View {
        Button(action: {
            onTapped()
        }, label: {
            Text("Share")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .foregroundColor(Color.white)
                .padding(16)
        })
            .background(Color.blue)
            .cornerRadius(8)
    }
}
