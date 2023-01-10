import Foundation

var testImagesDirectory: URL {
    URL.documents.appendingPathComponent("Test Images", isDirectory: true)
}

var testCaseIds: [UUID] {
    let files: [URL]
    do {
        files = try FileManager.default.contentsOfDirectory(
            at: testImagesDirectory,
            includingPropertiesForKeys: nil
        )
    } catch {
        print("Error getting Test Case Files: \(error)")
        files = []
    }
    let ids = files.compactMap { UUID(uuidString: $0.lastPathComponent.replacingOccurrences(of: ".jpg", with: "")) }
    print("\(ids.count) test cases")
    return ids
}

