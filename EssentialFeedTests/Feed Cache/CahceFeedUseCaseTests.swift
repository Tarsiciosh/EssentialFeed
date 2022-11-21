import XCTest

class LocalFeedLoader {
    init (store: FeedStore) {
        
    }
}

class FeedStore {
    var deleteCachedFeedCallCount = 0
}

final class CahceFeedUseCaseTests: XCTestCase {

    func test_initDoesNotDeleteCacheUponCreation () {
        let store = FeedStore()
        
        _ = LocalFeedLoader(store: store)
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
}
