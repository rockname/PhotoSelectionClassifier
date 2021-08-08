import Foundation

struct PhotoSelectionClassifierFileManager {
    private struct Constants {
        static let trainingDataPath = "TrainingData"
        static let selectedDataPath = "Selected"
        static let notSelectedDataPath = "NotSelected"
        static let classifierPath = "Classifier"
        static let classifierFileName = "PhotoSelectionClassifier.mlmodel"
        static let compiledClassifierFileName = "PhotoSelectionClassifier.mlmodelc"
    }

    private let fileManager: FileManager

    private var applicationSupportDirectory: URL {
        fileManager.urls(
            for: .applicationSupportDirectory,
               in: .userDomainMask
        ).first!
    }

    var trainingDataDirectory: URL {
        applicationSupportDirectory.appendingPathComponent(Constants.trainingDataPath)
    }

    var selectedDataDirectory: URL {
        trainingDataDirectory.appendingPathComponent(Constants.selectedDataPath)
    }

    var notSelectedDataDirectory: URL { trainingDataDirectory.appendingPathComponent(Constants.notSelectedDataPath)
    }

    var classifierURL: URL {
        applicationSupportDirectory
            .appendingPathComponent(Constants.classifierPath)
            .appendingPathComponent(Constants.classifierFileName)
    }

    var compiledClassifierURL: URL {
        applicationSupportDirectory
            .appendingPathComponent(Constants.classifierPath)
            .appendingPathComponent(Constants.compiledClassifierFileName)
    }

    var compiledClassifierFileExists: Bool {
        fileManager.fileExists(atPath: compiledClassifierURL.path)
    }

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func cleanTrainingDataDirectory() throws {
        if fileManager.fileExists(atPath: trainingDataDirectory.path) {
            try fileManager.removeItem(at: trainingDataDirectory)
        }
        try [selectedDataDirectory, notSelectedDataDirectory].forEach { url in
            try fileManager.createDirectory(
                at: url,
                withIntermediateDirectories: true
            )
        }
    }

    @discardableResult
    func preserveTemporaryClassifierURL(_ temporaryClassifierURL: URL) throws -> URL? {
        let file = try fileManager.replaceItemAt(
            compiledClassifierURL,
            withItemAt: temporaryClassifierURL
        )
        print("Compiled model successfully saved at \(String(describing: file))")
        return file
    }
}
