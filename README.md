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
####cache folder
```
/Users/{your-user-name}/Library/Caches/com.apple.dt.xctest.tool
```
### 2) Clarifying Requirements, Enhancing Cross-Team Domain Knowledge, and Iterative vs. Big Upfront Design

- narrative 
- use cases


### 3) Decoupling Use-Case Business Logic From Framework Details + Controlling Time + Multi-Method Abstractions Following The Interface Segregation and Single Responsibility Principles
```
there is going to be an intermediate object (LocalFeedLoader - sut) that will have a store (FeedStore) to communicate to the actual framework responsible of storing the data (could be a db, file system etc.)

T: the localFeedLoader (sut) does not invoke the delete command to the store upon creation (deleteChaedFeedCallCount = 0)

T: save command on sut requests cache deletion (save command receives also the items to be saved - create helper methods for the items uniqueItems) 

create the helper method makeSUT that returns the sut and the store as a named tuple

T: save commmand does not request insert command if deletion error ocurred (after we save we tell the store to complete the deletion command with an error - completeDeletion(with error: Error, at index: Int = 0) (only create the function and run the test)

T: save command requests New Cache Insertion On Successful Deletion: 
- create the funtion completeDeletionSuccessfully
- add the completion block to the deleteCacheFeed. 
- modify the FeedStore logic to capture these completions blocks and then update the completeDeletion(with: error) and completeDeletionSuccessfully. 
- implement the insert command that only increments the insertCallCount. 

#### save command requests New Cache Insertion With Time Stamp On Successful Deletion: make the currentDate be a dependency of the LocalFeedLoader. It is a closure that returns a Date. modify the tests to check the store insertions (not implemented) count to be 1, the items of the first element to be the passed items and the timestamp of the firt element to be the passed timestamp. remove previous test because it is redundant now. delete also the deleteCallCount. create the recevedMessages (private set) to store the receive message (ReceiveMessage enum) 

#### save command fails on deletion error. add a closure to the save command to receive the error. add receivedError to catch this error on the completion block and compared to the deletionError. in the save function completes in the root of the function with an error. 

#### save commands fails On Insertion Error. create the test with insertionError, completes deletion successfully and completes insertions with error. create the insertionsCompletions in the FeedStore to hold the completions then use new created completeInsertion(with:error) in the test. we can use the save completion to pass it to the insert completion because the both have the same signature.

#### test_save_succeedsOnSuccessfulCacheInsertion: add completeInsertionsSuccessfully to the store and make the test pass  
```

### 4) Proper Memory-Management of Captured References Within Deeply Nested Closures + Identifying Highly-Coupled Modules
```
T) test_save_DoesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated
- create a store and a sut
- inovoke save and capture the results in an array (receiveResults)
- deallocate sut
- completes deletion with error
- check for emptyness in the array
- change unknown to weak 
[guarantee that the `LocalFeedLoader` does not deliver deletion error after instance has been dallocated]

T) test_save_DoesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated
- repeat the same tests but with the insertion
- completes deletion succesfully 
- dallocat sut 
- completes insertion with error
- add weak 
[guarantee that the `LocalFeedLoader` does not deliver insertion error after instance has been deallocated]
- refactor code to return if error immediatelly - change name cacheDeletionError
[invert if logic to make code paths easier to follow]
- create and use cache(items, with: completion)
[extract cache insertion into a helper function to make logic inside closure callbacks easier to follow]
- move to `Feed Cache` folder
- make it public - only the needed parts
[move `LocalFeedLoader` (and `FeedStore` collaborator) to its own file in production]
[move `FeedStore` to its own file]
- create SaveResult type in LocalFeedLoader
[add SaveResult type alias to protect code from potential breaking changes]
```

### 5) Visualizing and Solving High-Coupling Issues by Decentralizing Components Using Data Transfer Model Representations
```
- the FeedStore creates an own LocalFeedItem and use it in the insert command
- the LocalFeedLoader creates a private extension of Array to map the FeedItems into LocalFeedItems
- fix the test code
- make the map of the items also in the tests
[add `LocalFeedItem` data transfer representation to decouple storage frameworks from `FeedItem` data models]
- create a uniqueItems funtion that return both models and local representation of the items as a named tuple
- replace all tests with this new helper
[simplify test setup and assertions with a factory helper method]
- remove the RemoteFeedItem from the FeedItemsMapper class to the root of the filemake it internal implicitly - remove computed property converter
- make the mapper response with RemoteFeedItems or throws the error (RemoteFeedLoader.Error.invalidData)
- the RemoteFeedLoader nows try to get the items and completes with error if an error ocurr 
- if it get the items it convert them to FeedItems (private extension on array toModels() ) 
- create a helper private static func map(_ data: Data, from response: HTTPURLResponse) -> Result
[add `RemoteFeedItem` data transfer representation to decouple the items mapper from `FeedItem` data models]
[move `RemoteFeedItem` to its own file]
[move `LocalFeedItem` to its own file] 
- rename LocalFeedItems to LocalFeedImage (and imageURL to url)
- rename FeedItem to FeedImage (and imageURL to url)
- search for 'item'
- renames item to image feed 
[remove references of `Items` in favor of `Images` which is a domain term used by domain experts in the specs]
```
