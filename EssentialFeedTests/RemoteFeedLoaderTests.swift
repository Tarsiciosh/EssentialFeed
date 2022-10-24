import XCTest
//@testable import EssentialFeed -> can have acces to all of these files
import EssentialFeed //test componenet only with public interfaces

final class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
    
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        //ARRANGE (GIVEN)
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        //ACT (WHEN)
        sut.load()
        
        //ASSERT (THEN)
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        //ARRANGE (GIVEN)
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        //ACT (WHEN)
        sut.load()
        sut.load()
        
        //ASSERT (THEN)
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        var captureErrors = [RemoteFeedLoader.Error]()
        sut.load { captureErrors.append($0) }
        
        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)
  
        XCTAssertEqual(captureErrors, [.connectivity])
    }
    
    //MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (Error) -> Void)]()
        
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (Error) -> Void) {
            messages.append((url,completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(error)
        }
    }
}


// pass the client in the constructor -> constructor injection
// as a property -> property injection
// or in the method -> method injection

/*
To test using a singleton:
- make "shared" in the singleton class be a variable
- move the test logic form the RemoteFeedLoader to the HTTPClient (capturing the url)
- to do that then we create a get method in the HTTPClient and capture the url there
- create a spy subclassing the singleton class with old things needed to the test and then change the singleton shared with the spy
- remove the private initializer to let the spy initialize

To start removing the singleton
- inject the client into the RemoteFeedLoader (constructor injection)
- remove the shared instance of the singleton class
- transform the abstract class HTTPClient to a protocol
- then the spy instead of inheriting the HTTPClient it implements the HTTPClient protocol
 
Test the URL is ok:
- assert if the url is the same as the one given to the RemoteFeedLoader (change to accept a URL)
 
Refactor things:
- create a makeSUT with a default URL and it returns a tuple of a sut and a client
- move the spy class to the test class (it is not part of the production code)
- move the requestedURL to the top of the class

Check response:
- add a completion block for the load function first only receiving an error
- add a default completion block so the other test don't fail
- create specific types of Error in the RemoteFeedLoader
 
- create an array of errors and compare this array
*/

