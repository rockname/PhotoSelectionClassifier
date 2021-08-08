import SwiftUI
import Photos

struct AlbumView: View {
    @State private var isPresented = false
    @StateObject private var viewModel: AlbumViewModel

    init(viewModel: AlbumViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ZStack {
                AlbumCollectionView(albumPhotos: $viewModel.albumPhotos)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        AddPhotoButton {
                            isPresented.toggle()
                        }
                    }
                }
            }
            .sheet(isPresented: $isPresented, onDismiss: {
                Task {
                    await viewModel.onPhotoPickerViewDismissed()
                }
            }, content: {
                PhotoPickerView(viewModel: PhotoPickerViewModel())
            })
            .navigationTitle("Album")
        }
        .navigationViewStyle(.stack)
        .onAppear {
            Task {
                await viewModel.onAppear()
            }
        }
    }
}

private struct AlbumCollectionView: View {
    private let gridItemLayout = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    @Binding var albumPhotos: [AlbumPhoto]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridItemLayout) {
                ForEach(albumPhotos) { albumPhoto in
                    GeometryReader { proxy in
                        AlbumGridView(
                            viewModel: AlbumGridViewModel(albumPhoto: albumPhoto),
                            targetSize: CGSize(
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

private struct AddPhotoButton: View {
    var onTapped: (() -> Void)

    var body: some View {
        Button(action: {
            onTapped()
        }, label: {
            Text("+")
                .font(.system(.largeTitle))
                .foregroundColor(Color.white)
                .padding(.bottom, 4)
        })
            .frame(width: 60, height: 60)
            .background(Color.blue)
            .cornerRadius(30)
            .padding()
            .shadow(
                color: Color.black.opacity(0.3),
                radius: 4,
                x: 4,
                y: 4
            )
    }
}
