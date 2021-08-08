import Foundation
import CreateML
import Combine

struct ImageClassifierTrainer {
    func execute(
        trainingDataDirectory: URL,
        modelParameters: MLImageClassifier.ModelParameters
    ) async throws -> MLImageClassifier {
        var cancellables = Set<AnyCancellable>()

        typealias TrainedImageClassifierContinuation = CheckedContinuation<MLImageClassifier, Error>
        return try await withTaskCancellationHandler(handler: {
            print("cancelled")
            // https://forums.swift.org/t/how-to-cancel-a-publisher-when-using-withtaskcancellationhandler/49688
//            cancellables.removeAll()
        }, operation: {
            return try await withCheckedThrowingContinuation { (continuation: TrainedImageClassifierContinuation) in
                do {
                    let job = try MLImageClassifier.train(
                        trainingData: .labeledDirectories(at: trainingDataDirectory),
                        parameters: modelParameters
                    )
                    job.result
                        .sink { completion in
                            switch completion {
                            case .failure(let error): continuation.resume(throwing: error)
                            case .finished: print("Finished to train an image classifier")
                            }
                        } receiveValue: { imageClassifier in
                            continuation.resume(returning: imageClassifier)
                        }
                        .store(in: &cancellables)
                    job.progress.publisher(for: \.fractionCompleted).sink { _ in
                        guard let progress = MLProgress(progress: job.progress) else { return }

                        print("Phase: \(progress.phase)")
                        print("Processed Item Count: \(progress.itemCount)")
                    }
                    .store(in: &cancellables)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        })
    }
}
