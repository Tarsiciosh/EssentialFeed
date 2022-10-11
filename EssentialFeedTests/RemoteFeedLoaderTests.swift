import XCTest

class RemoteFeedLoader {
    func load() {
        HTTPClient.shared.requestedURL = URL(string: "http://a-url.com")
    }
}

class HTTPClient {
    static let shared = HTTPClient()
    
    private init() {}
    
    var requestedURL: URL?
}

final class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClient.shared
        
        _ = RemoteFeedLoader()
    
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestDataFromURL() {
        //ARRANGE (GIVEN)
        let client = HTTPClient.shared
        let sut = RemoteFeedLoader()
        
        //ACT (WHEN)
        sut.load()
        
        //ASSERT (THEN)
        XCTAssertNotNil(client.requestedURL)
    }
}


// pass the client in the constructor -> constructor injection
// as a property -> property injection
// or in the method -> method injection
