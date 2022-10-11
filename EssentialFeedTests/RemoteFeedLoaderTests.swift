import XCTest

class RemoteFeedLoader {
    var client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    func load() {
        client.get(from: URL(string: "http://a-url.com")!)
    }
}

protocol HTTPClient {
    func get(from url: URL)
}

class HTTPClientSpy: HTTPClient {
    func get(from url: URL) {
        requestedURL = url
    }
    var requestedURL: URL?
}


final class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        _ = RemoteFeedLoader(client: client)
    
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestDataFromURL() {
        //ARRANGE (GIVEN)
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client)
        
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
2) move the test logic form the RemoteFeedLoader to the HTTPClient (capturing the url)
3) to do that then we create a get method in the HTTPClient and capture the url there
4) create a spy subclassing the singleton class with old things needed to the test and then change the singleton shared with the spy
5) remove the private initializer to let the spy initialize

 
To start removing the singleton
1) inject the client into the RemoteFeedLoader (constructor injection)
2) remove the shared instance of the singleton class
3) transform the abstract class HTTPClient to a protocol
4) then the spy instead of inheriting the HTTPClient it implements the HTTPClient protocol
*/
