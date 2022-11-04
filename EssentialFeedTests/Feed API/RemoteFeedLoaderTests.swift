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
        sut.load() { _ in }
        
        //ASSERT (THEN)
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load() { _ in }
        sut.load() { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: failure(.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
    
        let samples = [199, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: failure(.invalidData), when: {
                let json = makeItemsJSON([])
                client.complete(withStatusCode: code, data: json, at: index )
            })
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: failure(.invalidData), when: {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }

    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .success([]), when: {
            let emptyListJSON = makeItemsJSON([])
            client.complete(withStatusCode: 200, data: emptyListJSON)
        })
    }
    
    func test_load_deliversItemsOn200HTTPReponseWithJSONItems() {
        let (sut, client) = makeSUT()
        
        let item1 = makeItem(
            id: UUID(),
            imageURL: URL(string: "http://a-url.com")!
        )

        let item2 = makeItem(
            id: UUID(),
            description: "a description",
            location: "a location",
            imageURL: URL(string: "http://another-url.com")!
        )
        
        let items = [item1.model, item2.model]
        
        expect(sut, toCompleteWith: .success(items), when: {
            let json = makeItemsJSON([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: json)
        })
    }
    
    func test_load_doesNotDeliversResultAfterSUTInstanceHasBeenDeallocated() {
        let url = URL(string: "http://any-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load { capturedResults.append($0) }
        
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON([]))
        
        XCTAssert(capturedResults.isEmpty)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        url: URL = URL(string: "https://a-url.com")!,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)

        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        
        return (sut, client)
    }
    
    private func failure (_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result{
        .failure(error)
    }

    private func makeItem(
        id: UUID,
        description: String? = nil,
        location: String? = nil,
        imageURL: URL
    ) -> (model: FeedItem, json: [String: Any]){
        let item = FeedItem(
            id: id,
            description: description,
            location: location,
            imageURL: imageURL
        )
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].reduce(into: [String: Any]()){ (acc, e) in
            if let value = e.value { acc[e.key] = value}
        }
        return (item, json)
    }

    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    private func expect(
        _ sut: RemoteFeedLoader,
        toCompleteWith expectedResult: RemoteFeedLoader.Result,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ){
        let exp = expectation(description: "Wait for load completion")
        sut.load { receivedResult in
            //PATTERN MATCHING
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
            case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
 
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private class HTTPClientSpy: HTTPClient {

        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url,completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.success(data, response))
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

## A Classicist TDD Approach (No Mocking) to Mapping JSON with Decodable + Domain-Specific Models

-

 ***
 Every time the 'expect' method is called the spy capctures de parameters url and completion and stores
 them into the messages array (when the get mothod of the clienyt<spy> is executed),
 that's why then we can do client.complete(withStatusCode: code, at: index)
 with the correponding index becasue each time it appended a new completion closure
 ****
 
 
*/

