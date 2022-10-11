import XCTest

class RemoteFeedLoader {
    func load() {
        HTTPClient.shared.get(from: URL(string: "http://a-url.com")!)
    }
}

class HTTPClient {
    static var shared = HTTPClient()
    func get(from url: URL) {}
}

class HTTPClientSpy: HTTPClient {
    override func get(from url: URL) {
        requestedURL = url
    }
    var requestedURL: URL?
}


final class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        HTTPClient.shared = client
        
        _ = RemoteFeedLoader()
    
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestDataFromURL() {
        //ARRANGE (GIVEN)
        let client = HTTPClientSpy()
        HTTPClient.shared = client
        
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

/*
To test using a singleton:

1) make "shared" in the singleton class be a variable
2) move the test logic form the RemoteFeedLoader to the HTTPClient (capturing the url after calling get)
3) create a spy subclassing the singleton class with old things needed to the test and then change the singleton shared with the spy
4) remove the private initializer to let the spy initialize

*/
