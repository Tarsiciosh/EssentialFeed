import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case error(Error)
}

typealias ExampleResult = Result<[FeedItem], Error>

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
