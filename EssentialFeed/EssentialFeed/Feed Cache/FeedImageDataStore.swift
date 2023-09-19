import Foundation

public protocol FeedImageDataStore {
    func insert(_ data: Data, for url: URL) throws -> Void
    func retrieve(dataForURL url: URL) throws -> Data?
}
