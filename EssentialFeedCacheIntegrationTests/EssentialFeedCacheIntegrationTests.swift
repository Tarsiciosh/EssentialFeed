import XCTest
import EssentialFeed

final class EssentialFeedCacheIntegrationTests: XCTestCase {
    
    override func setUp() async throws {
        try await super.setUp()
        
        setupEmptStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        
        undoStoreSideEffects()
    }
    
    func test_load_deliversNoItemsOnEmptyCache() {
        let sut = makeSUT()
        
        let exp = expectation(description: "Wait for load completion")
        sut.load { result in
            switch result {
            case let .success(imageFeed):
                XCTAssertEqual(imageFeed, [], "Expected empty feed")
            default:
                XCTFail("Expected successful feed result, got \(result) instead")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_load_deliversItemsSavedOnASeparateInstance() {
        let sutToPerformSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let imageFeed = uniqueImageFeed().models
        
        let saveExp = expectation(description: "Wait for save completion")
        sutToPerformSave.save(imageFeed) { saveError in
            XCTAssertNil(saveError, "Expected to save successfully")
            saveExp.fulfill()
        }
        wait(for: [saveExp], timeout: 1.0)
        
        let loadExp = expectation(description: "Wait for load completion")
        sutToPerformLoad.load { result in
            switch result {
            case let .success(loadedImageFeed):
                XCTAssertEqual(loadedImageFeed, imageFeed, "Expected to load the feed")
            default:
                XCTFail("Expected successful feed result, got \(result) instead")
            }
            loadExp.fulfill()
        }
        
        wait(for: [loadExp], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath , line: UInt = #line) -> LocalFeedLoader {
        let storeBundle = Bundle(for: CoreDataFeedStore.self)
        let storeURL = testSpecificStoreURL()
        let store = try! CoreDataFeedStore(storeURL: storeURL, bundle: storeBundle)
        let sut = LocalFeedLoader(store: store, currentDate: Date.init)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
    
    private func setupEmptStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    private func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }
    
    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
}


