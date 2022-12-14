#  README

## FIRST MODULE - NETWORKING

// pass the client in the constructor -> constructor injection
// as a property -> property injection
// or in the method -> method injection

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

 ```
 Every time the 'expect' method is called the spy capctures de parameters url and completion and stores
 them into the messages array (when the get mothod of the clienyt<spy> is executed),
 that's why then we can do client.complete(withStatusCode: code, at: index)
 with the correponding index becasue each time it appended a new completion closure
 ```
 
- TEST IMPROVEMENTS
 
 EssentialFeed -> edit scheme -> Test -> Options (EssentialFeedTests) -> Randomize execution order
 EssentialFeed -> edit scheme -> Test -> Options (top Tab) -> gather coverage for: EssentialFeed
 
 Add a new target to the project:
 EssentialFeed -> + button -> Unit test bundle -> EssentialFeedEndToEndTests
 
 select the trackForMemoryLeaks file and Target membership to EssentialFeedEndToEndTests
 
 create a new scheme (from scheme right click) -> CI
 edit CI scheme -> test -> info -> add EssentialFeedAPIEndToEndTests and EssentialFeedTests (add randomize execution order and gather covergare for: EssentialFeed)
 
 - THREAD SANITIZER
 
 EssentialFeed -> edit scheme -> Run -> Diagnostics -> Thread Sanitizer
 
 at the end we leave it in the CI scheme to avoid CPU usage
 
 add runtime issue breakpoint


## SECOND MODULE - PERSISTANCE

### 1) URLCache as a Persistence Alternative & Solving The Infamous “But it works on my machine!” Caching Problem

#### code to demostrate some options:
``` swift 
let cache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024, directory: nil)
let configuration = URLSessionConfiguration.default

configuration.urlCache = cache
configuration.requestCachePolicy = .reloadIgnoringLocalCacheData

let session = URLSession(configuration: configuration)

let url = URL(string: "http://a-url")!
let request = URLRequest(url: url, cachePolicy: .returnCacheDataDontLoad, timeoutInterval: 30) 
```
