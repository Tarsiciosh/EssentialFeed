import Foundation

public protocol FeedImageDataLoader {
    func loadImageData(from: URL) throws -> Data
}
