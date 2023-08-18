#  NOTES

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
- renames item to image feed (unique initializers, end to end tests etc, also seraching for names of the functions) 
[remove references of `Items` in favor of `Images` which is a domain term used by domain experts in the specs]
```

### 6) Performing Calendrical Calculations Correctly, Dealing With Coincidental Duplication While Respecting the DRY Principle, Decoupling Tests From Implementation With Tiny DSLs, and Test Triangulation to Increase Coverage & Confidence
```
- create test LoadFeedFromCacheUseCaseTests
T) test_init_doesNotMessageStoreUponCreation
- copy makeSUT and FeedStoreSpy to this test (helpers) 
[LocalFeedLoader does not message store upon creation (before loading the feed from the cache store)]
- move the FeedStoreSpy to the Helpers folder (remove private)
[extract `FeedStoreSpy` into a shared scope to remove duplication]
T) test_load_requestsCacheRetrieval 
- create a sut and a store 
- execute the load command on the sut (add it to the local)
- compare the receivedMessages with the .retrieve message 
- add the retrieve command to store (FeedStore)
- catch the command by the spy (FeedStoreSpy)
[load command requests cache retrieval]
T) test_load_failsOnRetrievalError 
- copy the setup
- capture the error received in a closure (not available yet) into a receivedError variable (Error?)
- add and expectation since it is asynchronous code ("Wait for load completion")
- ask the store to complete with a retrievalError (completeRetrieval with:)
- add retrievalCompletions etc .. as NSError? (completion: completion)
[load command fails on retrieval error]
T) test_load_deliversNoImagesOnEmptyCache
- copy the setup
- capture the receivedImages in the closure (use LoadFeedResult)
- change completion closure signature to match this 
- create typeAlias LoadResult in LocalFeedLoader
- change the previous test commenting the current one
- default: XCTFail ("Expected failure, got \(result) instead"
[replace load command completion to return a result type rather than an option error]
- ask the store to complete with an emtpy cache (completeRetrievalWithEmptyCache)
[load command delivers no images on empty cache]
- create the expect function 
- use the switch (receivedResult, expectedResult)
- pass the file and line 
[extract duplicate test code into a shared helper method]
T) test_load_deliversCachedImagesOnLessThanSevenDaysOldCache
- coppy setup
- ask the store to complete with a feed (completeRetrieval with: localFeed, timestap: lessThanSevenDaysOldTimestamp)
- add extension to Date to add 7 days and extract one second using calendar adding(days:7).adding(seconds:-1)
- calendar.date(byAdding:value:to) (identifier gregorian)
- use the fixedCurrentDate (every time the production code ask for the current date we return the same fixed date)
- add completeRetrieval with feed: timestap: to spy 
- create RetrieveCahedFeedResult (empty, found, failure) in the FeedStore protocol file
- fix the spy 
- fix the load func in local (LocalFeedLoader)
- add conversion toModels  
[load command delivers cached images on less than seven days old cache] 
T) test_load_deliversNoImagesOnSevenDaysOldCache
- copy the setup
- add a where clause to the found case validate(timestamp) - use the calendar 
- calendar.date(byAdding:value:to)
- add a guard let to prevent crashing the app (production code)
[load command delivers no images on seven day old cache]
- create a private property for the calendar
- create maxCacheAgeInDays 
[extract local members into properties]
T) test_load_deliversNoImagesOnMoreThanSevenDaysOldCache
- moreThanSevenDaysOldTimestamp 
[load command delivers no images on more than seven days old cache]
```

### 7) Test-driving Cache Invalidation + Identifying Complex (Bloated) Functionality With The Command–Query Separation Principle
```
T) test_load_deletesCacheOnRetrievalError
- get a sut and store
- invoke load on sut 
- completes retrieval with an error 
- assert messeges received .retrieve .deleteCacheFeed
[deletes cache on retrieval error]
T) test_load_DoesNotdeleteCacheOnEmptyCache
- only .retrieve
[load command does not delete cache when cache is already empty]
T) test_DoesNotDeleteCacheOnLessThanSevenDaysOldCache
- get the setup from the other test
- complete retrieval with feeed and less that seven day old timestamp
[load command does not delete less than seven days old cache]
T) test_load_deletesCacheOnSevenDaysOldCache
- copy setup 
- expect .retrieve .deleteCacheFeed
- refactor load in LocalFeedLoader to make the test pass
[load command deletes seven days old cache upon retrieval]
T) test_load_deletesCacheOnMoreThanSevenDaysOldCache
[load command deletes more than seven days old cache upon retrieval]
T) test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated
- optional reference to the sut 
- capture the results (recievedResults)
- deallocate sut
- complete retrieval with empty cache
- expect empty receivedResults
- fix failing test
[load command does not deliver a load result after the instance has been deallocated to prevent unexpected behaviours in client's code]
```

### 8) Separating Queries & Side-effects for Simplicity and Reusability, Choosing Between Enum Switching Strategies, and Differentiating App-Specific from App-Agnostic Logic
```
- create test ValidateFeedCacheUseCaseTests 
T) test_init_doesNotMessageStoreUponCreation
- copy makeSUT
[LocalFeedLoader does not message store upon creation (before validating the cached feed)]
- change test_load_(hasNoSideEffectes)deletesCacheOnRetrievalError
- .retrieve only 
- fix the code
T) test_validateCache_deletesCacheOnRetrievalError
- call validateCache on sut 
- create the validateCache with the minimum to make the test pass
[extract cache deletion side-effect from retrieval error from `load` method to the `validateCache` method]
- change test_load_(hasNoSideEffects)DoesNotdeleteCacheOnEmptyCache
- .retrieve only
T) test_validateCache_doesNotDeleteCacheOnEmptyCache
- change validateCache logic
[validate cache command does not delete cache when cache is already empty]
- change test_load_(hasNoSideEffects)DoesNotDeleteCacheOnLessThanSevenDaysOldCache
T) test_validateCacheDoesNotDeleteLessThanSevenDaysOldCache
[validate cache command does not delete less than seven days old cache]
- create the FeedCache/Helpers/FeedCacheTestHelpers
- create Helpers/SharedTestHelpers (anyNSError)
[extract duplicate helpers into a shared scope]
- change test_load_(hasNoSideEffects)deletesCacheOnSevenDaysOldCache
- change test_load_(hasNoSideEffects)deletesCacheOnMoreThanSevenDaysOldCache
T) test_validateCache_deletesSevenDaysOldCache
T) test_validateCache_deletesMoreThanSevenDaysOldCache
- add case found with no cache where not valid
- explicit case .found, .empty: break
[extract cache deletion side-effects on expired cache from the `load` method to the `validateCache` method]
T) test_validateCache_DoesNotDeleteInvalidCacheAfterSUTInstanceHasBeenDeallocated
- complete retrieval with an error
[validate cache command does not delete invalid cache after instance has been deallocated]
- combine found and empty cases 
[group cases to remove duplication]
- create extesion for the methods in LocalFeedLoader - func cache 
[segment functionality into extensions]
- make LocalFeedLoader conform to FeedLoader
[make LocalFeedLoader conform to FeedLoader]
[move typealiases to appropiate segment]
```

### 9) Separating App-specific, App-agnostic & Framework logic, Entities vs. Value Objects, Establishing Single Sources of Truth, and Designing Side-effect-free (Deterministic) Domain Models with Functional Core, Imperative Shell Principles

```
- create FeedCachePolicy
- inject it in the LocalFeedLoader
[extract cache validation policy into the new `FeedCachePolicy` type]
- add against date: Date to the validate instead of having the currentDate
[make the `FeedCachePolicy` a pure type with no side-effects (deterministic)]
[make `FeedCachePolicy` static since it doesn't keep any state]
- move it to the Feed Cache/FeedCachePolicy
[move `FeedCachePolicy` to its own file]
- change test (OnNonExpiredCache) nonExpiredTimestamp
- create the minusFeedCacheMaxAge (FeedCacheTestHelpers)
- change test (OnCacheExpiration) expirationTimestamp
- change test (OnExpiredCache) expiredTimestamp
- chang all other tests (from both use cases)
[hide cache expiration details from tests with a new DSL method to protect tests from breaking changes]
- create feedCacheMaxAgeInDays (in the extension)
[move feed cache max age (7 days) to a computed var to clarify intent in code]
[separate `Date` extension helpers into distinct contexts to clarify their scope (one is a cache-policy specific DSL and the other is just a reusable DSL helper)]
```

### 10) Dependency Inversion Anatomy (High-level | Boundary | Low-level), Defining Inbox Checklists and Contract Specs to Improve Collaboration and Avoid Side-effect Bugs in Multithreaded Environments
```
- Retrieve 
    - Empty cache returns empty
    - Empty cache twice returns empty (no-side-effects)
    - Non-empty cache returs data
    - Non-empty cache twice returns the same data (no side-effects)
    - Error retuns error (if applicable, e.g., invalid data)
    - Error twice returns same error (if applicable, e.g., invalid data)

- Insert 
    - To empty cache stores data
    - To Non-empty cache overrides previous data with new data
    - Error (if applicable, e.g., no write persmission)

- Delete 
    - Empty cache does nothing (cache stays empty and does not fail)
    - Non-empty cache leaves cache empty
    - Error (if applicable, e.g., no delete permission)

- Side-effects must run serially to avoid race-conditions
    
```

### 11) Persisting/Retrieving Models with Codable+FileSystem, Test-driving in Integration with Real Frameworks Instead of Mocks & Measuring Test Times Overhead with `xcodebuild`

```
- create test file CodableFeedStoreTests
T) test_retrieve_deliversEmptyOnEmptyCache
- create the sut (CodableFeedStore)
- create actual CodableFeedStore
- invoke command retrieve with the corresponding closure
- create retrieve command on CodableFeedStore
- aim for empty result (switch break) 
- fail on all others cases "Expected empty result, got result instead"
- add expectation "Wait for cache retrieval"
- make CodableFeedStore complete with empty case
[retrieving from empty cache delivers empty result]
T) test_retrieve_hasNoSideEffectOnEmptyCache() 
- copy previous test
- call retrieve twice (in cascade)
- use patern matching to aim for the two empty results 
- fail on all other cases "Expected retrieving twice from empty cache to deliver same empty result, got firstResult and secondResult instead"
[retrieving from empty cache twice delivers same empty result (no side-effects)]
T) test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues
- copy previous test 
- call insert and then retrieve (in cascade)
- create insert command on CodableFeedStore
- create a feed and a timestamp
- assert insertionError to be nil ("Expected feed to be inserted successfully")
- aim for the retrievedFeed and retrievedTimestamp of the found case
- assert they match the previous created ones
- fail on all other cases "Expected found result with feed and timestamp, got retrieveResult instead"
- test to complete insert with error and nil to see the results
- implement insert on CodableFeedStore 
- create an enconder (JSONEncoder)
- create private struct Cache (feed and timestamp) encodable
- encode struct / encoder.encode(Cache(feed: feed, timestamp: timestamp))
- write to file / encoded.write(to: storeURL)
- storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
- complete with nil
- in retrieve method do the oposite
- get data from file / Data(contentsOf: storeURL) use guard to complete with empty
- decode data to cache / decoder.decode(Cache.self, from: data)
- remove file after test in the tearDown function (FileManager.default.removeItem(at: storeURL))
- add a breakpoint to not let the tearDown execute 
- and also in the setUp  
[retrieving after inserting to empty cache delivers inserted values]
- remove conformance to Codable from LocalFeedImage
- create CodableFeedImage conforming to Codable with the same properties (private)
- add localFeed property in Cache to map the feed into [LocalFeedImage]
- add computed var local in CodableFeedImage to convert to LoacalFeedImage
- add initilizer for CodableFeedImage receiving a LocalFeedImage
- map the feed with the initializer (using () instead of {})
[move `Codable` conformance from the framework-agnostic `LocalFeedImage` type to the new framework-specific `CodableFeedImage` type. The `CodableFeedImage` is a private type within the framework implementation since the `Codable` requirement is a framework-specific detail]
- create the makeSUT factory 
[extract system under test (sut) creation into a factory method]
- add memory leak tracking
[add memory leak tracking]
- make storeURL be a explicit dependency (constructor injection)
- inject it in the makeSUT upon creation
[extract hardcoded store URL from the `CodableFeedStore` production type making it an explicit dependency (passed in by the tests so far)]
- create a factory method to create the storeURL
[extract duplicate store URL creation into a helper factory method]
- change the file name to the name of the test / \(type(of: self))
- change to caches directory (cachesDirectory)
- rename to testSpecificStoreURL
[replace production store url with a test-specific store URL to avoid sharing state/artifacts with other parts of the system (including other tests)]
- create setupEmptyStoreState, undoStoreSideEffects and deleteStoreArtifacts
[add helper methods to provide documentation, context and clarify test `setUp` and `tearDown` intent regarding side-effects]
- xcodebuild clean build test -project EssentialFeed.xcodeproj -scheme "EssentialFeed" 
```

### 12) Deleting Models and Handling Errors with Codable+FileSystem, Making Async Code Look Sync in Tests to Eliminate Arrow Anti-Pattern, and More Essential Test Guidelines to Improve Code Quality and Team Communication

```
T) test_retrieve_hasNoSideEffectsOnNonEmptyCache
- copy previous test
- retrieve twice (in cascade)
- compare firstResult and secondResult using pattern matching (firstFound, secondFound) with feed and timestamp
- fail is other case "Expected retrieving twice from non empty cache to deliver same found result with (feed) and (timestamp), got (firstResult) and (secondResult) instead"
[retrieving from no-empty cache twice delivers same found result (no side-effects)]
- create expect(sut, toRetrieve expectedResult) (empty and found) add file and line "Expected to retrieve \(expectedResult), got \(retrieveResult) instead"
- refactor test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues (call insert and then expect after the wait)
- refactor test_retrieve_deliversEmptyOnEmptyCache (call expect)
[extract duplicate retrieve test code into a reusable helper method]
- refactor test_retrieve_hasNoSideEffectsOnEmptyCache
- create expect(sut toRetrieveTwice expectedResult) calling expect twice
- refactor test_retrieve_hasNoSideEffectsOnNonEmptyCache expectation "Wait for cache insertion"
[extract duplicate no-side-effects-on-retrive test code into a reusable helper method]
- create insert(cache, to sut)
- refactor tests with insert 
[extract duplicate insert code into a reusable helper mehod]
- rename test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues -> deliversFoundValuesOnNonEmptyCache
[improve test name to follow convention]
T) test_retrieve_deliversFailureOnRetrievalError
- create sut 
- write file with invalid json (try! "invalid data" write to atomically false encoding utf8)
- expect sut to retrieve with failure (anyNSError)
- refactor retrieve into do catch block 
- refactor expect to break also on matching failure
[retrieve delivers failure on retrival error (invalid cached data)]
- make a correlation of the url with the sut 
- change makeSUT to receive the url with a default value nil (if passed one use that otherwise use the default)
[make the storeURL explicit within the test to facilitate debugging if this test ever fails (all relevant details within a test method should be clearly visible)]
T) test_retrieve_hasNoSideEffectsOnFailure
- create the invalid file and expect to retrieve twice with failure
[retrieving from invalid cache twice delivers same failure result (no side-effects)]
T) test_insert_overridesPreviouslyInsertedCacheValues
- first insert with in-line data (assert nil firstInsertionError) 
- second insert with latestFeed latestTimestamp and latestInsertionError
- expect to retrieve found latestFeed and latestTimestamp
- refactor insert to capture the insertionError and return it
- add @discardableResult 
[inserting to non-empty cache overrides previously inserted cache values]
T) test_insert_deliversErrorOnInsertionError
- create a invalidStoreURL "invalid://store-url"
- create the sut with that url
- insert and expect insertionError to be not nil
- refactor insert code with do catch 
[insert delivers error on insertion error (invalid store URL)]
- create deleteCache in CodableFeedStore 
- create a (deleteCache from sut) helper
T) test_delete_hasNoSideEffectsOnEmptyCache 
- create sut
- call delete
- expect deletionResult to be nil
- expect sut to retrieve empty
T) test_delete_emptiesPreviouslyInsertedCache
- create sut 
- insert feed
- delete cache
- expect deletionResult to be nil
- expect sut to retrieve empty
T) test_delete_deliversErrorOnDeletionError
- create sut with noDeletePermissionURL (cachesDirectory)
- delete cache
- expect deletionResult to be not nil
- add guard FileManager.default.fileExists(atPath:)
- make CodableFeedStore conform to FeedStore
- delete namespacing 
[make `CodableFeedStore` conforms to `FeedStore`]
- replace CodableFeedStore references with FeedStore
[replace concrete `CodableFeedStore` dependency in tests with the `FeedStore` protocol to make tests more decoupled from the concrete production implementations (also proving we respect the Liskov Substitution Principle)]
"Types in a program should be replaceable with instances of their subtypes without altering the correctness of that program"
- move CodableFeedStore to FeedCache/
- make public what necessary
[move `CodableFeedStore` to its own file in production]
```

### 13) Designing and Testing Thread-safe Components with DispatchQueue, Serial vs. Concurrent Queues, Thread-safe Value Types, and Avoiding Race Conditions

```
T) test_storeSideEffects_runSerially
- create a sut 
- create an op1 operation (expectation) with a insert command
- create p2 with deleteCacheFeed
- create completedOperationsInOrder array of XCTestExpectation
- append the operations to the array
- create p3 with insert 
- wait for the expectation (waitForExpectations)
- assert the operations are in right order "Expected side-effects to run serially but operations finish in the wrong order"
[proved that the `CodableFeedStore` side-effects run serially]
- dispath retrieve code to the global queue (DispatchQueue.global().async)
- create a storeURL constant and capture only this value instead of the hole object
- copy the same for all other methods
- run test to see failing 
- create a shared queue (DispatchQueue(label: "\(CodableFeedStore.self)Queue", qos: .userInitialed))
- use the shared queue (private constant property of CodableFeedStore)
[dispatch `CodableFeedStore` operations in a serial background queue to avoid blocking clients]
- change queue to be concurrent (attributes: .concurrent)
- add barrier flags to the operations that has side-effects (flags: .barrier)
[make `CodableFeedStore` queue concurrent to allow multiple `retrieve`  to be processed in parallel (since it has no side-effects) and user `barriers` when performing side-effects to guarantee data consistency and avoid race conditions]
- add comments to the functions of the FeedStore protocol
"/// The completion handler can be invoked in any thread."
"/// Clients are resposible to dispatch to appropriate threads, if needed."
[add comments to document that a completion handlers in any `FeedStore` implementation can be invoked in any thread. Clients are responsible to dispath to appropriate threads, if needed]
- add same comments to HTTPClient protocol 
[add comments to document that a completion handlers in any `HTTPClient` implementation can be invoked in any thread. Clients are responsible to dispath to appropriate threads, if needed]
- xcodebuild clean build test -project EssentialFeed/EssentialFeed.xcodeproj -scheme "EssentialFeed"
``` 

### 14) Protocol vs Class Inheritance, Composite Reuse Principle, and Extracting Reusable Test Specs with Protocol Inheritance, Extensions and Composition

```
- create a protocol FeedStoreSpecs (in CodableFeedStoreTests)
- see the generated interface (Ctrl + Cmd + up)
- copy the methods to the protocol
- create a another protocosl for the errors called 
- FailableRetrieveFeedStoreSpecs
- FailableInsertFeedStoreSpecs
- FailableDeleteFeedStoreSpecs
- brake down tests with two assertions into to single tests
[break down `CodableFeedStore` tests to guarantee there's only one assertion per test. The goal is to clarify the behavior under test in small units, so we can extract the behavior tests into reusable specs. ]
- use protocol inheritance to force FailableRetrieveFeedStoreSpecs also conform to FeedStoreSpecs
- make CodableFeedStoreTests conform to all Failable protocolos
- use protocol composition to have one FailableFeedStore (typealias wiht &)
- move protolos to there own file EssentialFeedTests/FeedCache/FeedStoreSpecs
[create `FeedStoreSpecs` that must be implemented by any `FeedStore` test implementation to guarantee it meets spec]
- extract FeedStore helper methods to a helper file XCTestCase+FeedStoreSpecs
(extension of the FeedStoreSpecs (where Self: XCTestCase)
- paste the method and remove the private access control
[extract reusable `FeedStoreSpecs` helper methods into a shared scope so it can be used by other `FeedStore` implementation tests]
- add assertThatRetrieveDeliversEmptyOnEmptyCache(on sut)
- change alls tests to assertion functions
[]

```

### 15) Core Data Overview, Implementation, Concurrency Model, Trade-offs, Modeling & Testing Techniques, and Implementing Reusable Protocol Specs
```
- create EssentialFeedTests/FeedCache/CoreDataFeedStoreTests
- add conformance to the FeedStoreSpecs (add protocol stubs)
[add empty CoreData feed store specs]
- create Feed Cache/CoreDataFeedStore 
- add conformance to the FeedStore protocol (add protocol stubs)
T) test_retrieve_deliversEmptyOnEmptyCache
- add makeSUT 
- complete with empty
[`CoreDataFeedStore.retrieve()` delivers empty on empty cache]
T) test_retrieve_hasNoSideEffectsOnEmptyCache
- assertThatRetrieveHasNoSideEffectsOnEmptyCache
[`CoreDataFeedStore.retrieve() has no side-effects on empty cache]
- add CoreDataFeedStore model Feed Cache/FeedStore (add FeedStore.xcdatamodeld file)
- add entities to the file
- set Codegen to Manual/None (for the entities)
- add relationships cache <-> feed (with inverse feature)
[add CoreDataFeedStore data model]
- add ManagedCache and ManagedFeedImage (CoreDataFeedStore)
[add ManagedCache and ManagedFeedImage model representations]
- add load(modelName:in:) extension to NSPersistentContainer (CoreDataFeedStore file)
- add with(name:in:) extension to NSManagedObjectModel (CoreDataFeedStore file)
- add container (NSPersistentContainer) to CoreDataFeedStore
- create init(bundle:) for CoreDataFeedStore (initilizing the container)
[load persistent container store upon CoreDataFeedStore initialization]
- add context (NSManagedObjectContext) to CoreDataFeedStore
[add private background context to perform store operations]
- add description(url) to the container 
[make storeURL an explicit dependency so we can inject test-specific URLs (such as `/dev/null`) to avoid sharing state with production (and other tests!)] 
T) test_retrieve_deliversFoundValuesOnNonEmptyCache
- add retrieve and insert logic to CoreDataFeedStore
[`CoreDataFeedStore.retrieve()` delivers found values on non-empty cache]
- add localFeed to ManagedCache
- add static image(from:in:) to ManagedFeedImage
- add local to ManagedFeedImage
[extract model translations into helper methods within the managed models]
- create find(in:) in ManagedCache
[extract ManagedCache fetch request logic into a helper method within the managed model class]
T) test_retrieve_hasNoSideEffectsOnNonEmptyCache
[`CoreDataFeedStore.retrieve()` has no side-effects on non-empty cache]
T) test_insert_deliversNoErrorOnEmptyCache
[`CoreDataFeedStore.insert() delivers no error on empty cache]
T) test_insert_deliversNoErrorOnNonEmptyCache
[`CoreDataFeedStore.insert()` delivers no error on non-empty cache]
T) test_insert_overridesPreviouslyInsertedCacheValues
- add newUniqueInstance to ManagedCache (delete all found caches)
[`CoreDataFeedStore.insert()` overrides previously inserted cache values]
T) test_delete_deliversNoErrorOnEmptyCache
- complete delete with nil
[`CoreDataFeedStore.deleteCachedFeed()` delivers no error on empty cache]
T) test_delete_hasNoSideEffectsOnEmptyCache
[`CoreDataFeedStore.deleteCachedFeed()` has no side-effects on empty cache]
T) test_delete_deliversNoErrorOnNonEmptyCache
[`CoreDataFeedStore.deleteCachedFeed()` delivers no error on non-empty cache]
T) test_delete_emptiesPreviouslyInsertedCache
- add code to find delete and save
[`CoreDataFeedStore.deleteCachedFeed() empties previously inserted cache]
T) test_storeSideEffects_runSerially
[proved that `CoreDataFeedStore` side-effects run serially]
- create "perform" helper in CoreDataFeedStore (take an action that receives a context and return Void)
[extract duplicate code into a reusable helper method]
[move `CoreDataFeedStore` files to the new infrastructure folder]
[move `CodableFeedStore` to the new infrastructure folder]
[extract reusable CoreData helpers into a separate file]
[extract CoreData managed model classes into separate files]
[separate CoreData managed model classes data from helpers with extensions]
```

### 16) Finishing the Cache Implementation with Business Logic + Core Data Integration Tests—Unit vs. Integration: Pros/Cons, Performance, Complexity & How to Achieve The ideal Testing Pyramid Distribution

```
- create a new test target for the cache integration tests:
- (+ in the project -> macOS -> macOS Unit Testing Bundle)
- Product Name: EssentialFeedCacheIntegrationTests 
- in the scheme chooser select: Manage Schemes
- select EssentialFeedCacheIntegrationTests -> Edit
- go to Test tab
- Info -> options -> select Randomize execution order
- Options -> Gather coverage (some targets) for EssentialFeed
- now there is a new folder with a new file for the integration tests
[add `EssentialFeedCacheIntegrationTests` target to separate the potentially-slower cache integration tests from the the fast unit/isolated tests]
T) test_load_deliversNoItemsOnEmptyCache
- create a sut (add createSUT with LocalFeedLoader)
- perfom a load operation expecting a success result with an empty array
- for the LocalFeedLoader we use a CoreDataStore and Date.init
- configured with testSpecificStoreURL:
- FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
- and storeBundle: Bundle(for: CoreDataFeedStore.self)
- add helper function trackForMemoryLeaks to the integration target (to be able to use them)
- to see a failing test change the implementation of the CoreDataFeedStore to return an error instead of a successful response (return completion(.failure(NSError(domain: "error", code: 0))) )
[include memory leak tracking helper in the cache integration tests target]
[`LocalFeedLoader` in integration with the `CoreDataFeedStore` delivers no items on empty cache]
T) test_load_deliversItemsSavedOnASeparateInstance
- sutToPerformSave
- sutToPerformLoad
- create a feed and compare it with the imageFeed (loaded)
- add helper functions uniqueImageFeed and anyURL to integration target to be able to use them
[include cache test helper in the cache integration tests target]
- add setUp (setupEmptStoreState) and tearDown (undoStoreSideEffects) methods:
- deleteStoreArtifacts(): try? FileManager.default.removeItem(at: testSpecificStoreURL()) 
[clean up and undo all cache side effects on `setUp` and `tearDown` to avoid sharing state between tests]
[`LocalFeedLoader` in integration with the `CoreDataFeedStore` delivers items saved on separate instances, proving we correctly persist the data models to disk]
- add expect(toLoad:) helper method, use example: expect(sut, toLoad: [])
[extract duplicate cache load expectations into a shared helper method]
T) test_save_overridesItemsSavedOnASeparateInstance
- sutToPerformFirstSave, sutToPerformLoad, sutToPerformLastSave, firstFeed, latestFeed
[`LocalFeedLoader` in integration with `CoreDataFeedStore` overrides items saved by separate instances, proving we correctly managed the data models on disk]
- create save(:with) helper method (
[extract duplicate cache save operation into a shared helper method]
- change CoreDataFeedStore with CodableFeedStore and see that tests are passing
[delete the `CodableFeedStore` in favor of the `CoreDataFeedStore` (we just need one in this project). If needed, of course, we can revert this commit and restore the `Codable` implementation]
- configure the CI scheme to include the integration test:
- Test(left-tab)->Info(top-tab) + EssentialFeedCacheIntegrationTests 
- then in the options select Randomize execution order 
[include `EssentialFeedCacheIntegrationTests` test target in the CI scheme to guarantee we build and run all cache integration tests as part of the continuous integration pipeline]
see the logs for test times (last option in the left top tabs)
```

### 17) bonus - Improving Model Composability With Swift’s Standard Result and Optional Types, Map, Functors, and Powerful Refactorings Backed by Tests and Types (Compiler!)

```
- Warning Swift convertion: Convertion to Swift 5 is available
- select all the targets
- result: no source changes necessary
- run the test in CI scheme
[migrate to Swift 5 (no source changes nedded)]
- enable base internationalization
- run tests again
[enable Base Intenationalization (a recommended setting in the Xcode 10.2.1)]
- global search for intenal an remove it globally
- run teh test
[remove redundant internal access control declarations]
[replace depricated initializer for Data]
- no more warnings
- change the reduce code with the new compactMapValues
[replace `reduce` implementation to remove `nil` values from the dictionary with the `compactMapValues` method]
- search for Result (custom)
- LoadFeedResult (transform into a typealias) Result<[FeedImage], Error>
[replace custom `LoadFeedResult` enum with the standard `Swift.Result`]
- move the LoadFeedResult to the FeedLoader protocol and rename it to Result (using Swift.Result for the Swift Result)
- fix the braking changes (FeedLoader.Result)
[nest `LoadFeedResult` into the `FeedLoader` protocol as `FeedLoader.Result` since they're closely related]
- HTTPClientResult (repeat the same steps - typealias, nesting) fix - put values inside a tuple
[replace custom `HTTPClientResult` enum with a nested typealias over the standard `Swift.Result`]
- RetrieveCachedFeedResult 
- create new CachedFeed (empty and found) compose the RetrieveCachedFeedResult with that
- fix all type errors
- move inside the protocol as RetrievalResult
[replace custom `RetrieveCachedFeedResult` enum with a nested typealias over the standard `Swift.Result` (`FeedStore.RetrievalResult`)]
- replace CachedFeed with a struct holding a public feed and a timestamp (add public init)
- use an optional CachedFeed in the RetrievalResult  
- fix all type errors (.some .none and CachedFeed)
- convert struct CachedFeed to tuple
[refactor `CachedFeed` type from `enum` to `tuple` since we can represent the absence of a value with an `Optional`]
- add typealias DeletionResult and InsertionResult (Error?)
[add typealias for `FeedStore.DeletionResult` and `FeedStore.InsertionResult`]
- change DeletionResult and InsertionResult to Result<Void, Error>
- in LocalFeedLoader save func change completion code to use the result and switch statement (deletionResult)
- in LocalFeedLoader also change SaveResult
- IMPORTANT CODE: < if case let Result.failure(error) = result { deletionError = error } > 
[replace occurrences of `Error?` for representing operation sucess/failure with `Result<Void, Error>`]
- refactor code in CoreDataFeedStore
- completion(Result(catching: { if .. return ... else .. return))
- for success it wraps the values to a success case. When throwing an error it wraps the error into a failure case
- map the find value into cache and use it to return the CachedFeed (find returns an optional ManagedCache) a tuple with (nil, nil) is handle as nil?
- remove the unneeded catching 
- replace the cache with the $0
- can even delete the return statemnt (T)
- repeat the same for the other methods
[simplify `CoreDataFeedStore` completion code with the new `Result` APIs]
- do the same with the URLSessionHTTPClient
[simplify `URLSessionHTTPClient` completion code with the new `Result` APIs]
- update CI config to support swift 5 (vim .travis.yml (osx_image: xcode10.2))
[update Travis CI config to build and test with Xcode 10.2]
``` 

## THIRD MODULE - UI + PRESENTATION

### 1) Gathering Fast Feedback and Validating UI Design and Dev Decisions Through Realistic App Prototypes
```
- create new project called Prototype (iOS Single View App) no Core Data, Unit Tests or UI Tests in the same project folder
- chose device orientation portrait (disable landscape left and right)
- Bundle Indetifier: (..).EssetialFeed.Prototype
- remove ViewController file (also the class in the storyboard)
[add empty project for prototype]
- remove the old viewcontroller and add a table view controller
- embed it in a navigation controller (Editor -> Embed in)
- set the navigations controller as initial view controller (Is Initial View Controller) 
- configure protoype cell (two labels and two images):
- stack name and pin view in ah horizontal stack view (Editor  -> Embed in -> Stack View) (spacing 6)
- add the asset images for the pin
- set the image as the pin 
- rename the stack to Location Container
- stack now the tree views vertically (spacing 10)
- pin this stack to the content view (bottom gear - all set to 0 - Constrain to margins)  
- add extra bottom and top space (6) set low priority (999) (right panel) to avoid contraints warnings
- IMPORTANT ADVICE: SET LOW PRIORITY TO THE VERTICAL CONSTRAINTS FOR THE CELL 
- embed the image view in a view (Image Container)
- set background color (E3E3E3) (RGB Sliders)
- User Defined Runtime Attributes (Identity inpector) - layer.cornerRadius (number) value 22
- add Clip to Bounds
- make the image container have equal width with the parent Stack View (ctrl + drag) 
- add aspect ration Multiplier 1:1 (ctrl drag to itself)
- pin the imaga inside the container to all of the sides with no margin (no Constrain to margings) 
- add long content to the description label (change lines to 6)
- set the color (4A4A4A) font size (16)
- add long content to the location label (change line to 2)
- set the color (9B9B9B) font size (15)
- embed the pin view into a view (Pin Container)
- set the width (10)
- pin the image to the top and leading and make height (14)
- set the Location Container to be equal width of the superview (Stack View)
- set Location Container Stack Allignment to top
- change row height 580 (only for pre viewing purposes)
- pin top constraint (3)
- add Reusable indentifier: FeedImageCell (Attibutes Inspector)
- Table View - Separator None
- Cell - Selection None
[add prototype storyboard with table view and feed cell layout]
- create a view controller FeedViewController (UITableViewController)
- number of rows (10)
- cell for row return the cell with the "FeedImageCell" identifier
- set the FeedViewController as the class of the table view controller in storyboard
- we should see 10 cell in screen
- add views to the table header and footer
- set height (16) for both (right panel)
- set title for navigation bar (My Feed) (Navigation Item - left panel)
- ammend the changes (only storyboard file)
[add `FeedViewController` rendering 10 cells]
- create FeedImageViewModel struct (description(?), location(?), imageName) in the controller file
- create FeedImageViewModel+PrototypeData file
- create an extension of FeedImageModel with a static var prototypeFeed with an array of FeedImageViewModels
- add images to the assets catalog
[add prototype feed data for demoing puposes]
- create FeedImageCell with outlets (locationContainer, locationLabel, feedImageView, descriptionLabel)
- e.g. @IBOutlet private(set) var locationContainer: UIView!
- change the class type in storyboard
- connect the outlets with ctrl + drag
[add `FeedImageCell` with storyboard connections]
- add private feed (with FeedImageViewModel.prototypeFeedc) to the FeedViewController
- update the table view functions
- cast the cell to the FeedImageCell
- then cell.configure(with: model) 
- add and extension to the FeedImageCell (in the FeedViewController file)
- create the configure(with:) func
- set all the data olso the hidden views
- e.g. description.isHidden = model.description == nil
[render prototype feed data on the table view]
- create the fadeIn method to simulate the loading of the views
[add fade-in animation to simulate "asynchronous image loading"]
[add app icon] 
```

### 2) Supporting Multiple Platforms with Swift Frameworks While Separating Platform-specific Components to Facilitate Loose Coupling and Speed up Development
 ```
- EssentialFeed Project -> EssentialFeed Target -> Build Settings (all - combined) -> architectures -> supported platforms: add (iphoneos iphonesimultator) 
- add iphoneos and iphonesimulator to the EssentialFeedTests target
[make `EssentialFeed` and `EssentialFeedTests` targets support macOS and iOS since they're platform-independent (can run on any platform!)]
- add iphoneos and iphonesimulator support to the EssentialFeedAPIEndToEndTests target
- create a new scheme EssentialFeedEndToEndTests (to run the end to end test in isolation)
- Test tab (Options) Gather covarage for EssentialFeed target, (Info) Randomize execution order  
[make `EssentialFeedAPIEndToEndTests` target support macOS and iOS since it's platform-independent (can run on any platform!)]
- add iphoneos and iphonesimulator to the EssentialFeedCacheIntegrationTests (with an scheme already)
[make `EssentialFeedCacheIntegrationTests` target support macOS and iOS since it's platform-independent (can run on any platform!)]
- add new framework EssentialFeediOS (+ in the project) (Cocoa Touch Framework) include unit tests
- it added two new targets that support only iOS (EssentialFeediOS and EssentialFeediOSTests)
- delete apple added files (EssentialFeediOS.h and EssentialFeediOSTests.swift)
- configure the EssentialFeediOS scheme (randomize order, gather coverage for EssentialFeediOS)
[add `EssentialFeediOS` framework (prod and test) target for iOS platform-specific components]
- add this new framework to the CI (canot add in the current CI scheme because it is platform independent)
- tap on duplicate scheme, rename to CI_iOS (add the EssentialFeediOSTests) (randomize execution order, gather coverage for EssentialFeediOS also) tapped on Shared (to let the CI server have access)
- rename old CI to CI_macOS
- update the ci config file to run both, the macOS independent tests on macos on mac platform/destination and macOS and iOS tests on iOS platform/destination
[add separate CI schemes for macOS and iOS as we now have an iOS-specific target that should no be tested on macOS]
```

### 3) Apple MVC, Test-driving UIViewControllers, Dealing with UIKit’s Inversion of Control & Temporal Coupling, and Decoupling Tests from UI Implementation Details
```
(on the Prototype project)
- change FeedViewController to start with an empty feed
- when the view will appears call refresh (@IBAction func)
- refresh first make the refreshControll beginRefreshing
- and dispatch async (1.5) to load the data from prototypeFeed and reload table (if feed is emtpy). Then call endRefreshing
- setup the refresh control in storyboard (set refreshing property to enabled) 
- then connect the refresh action with the Refresh Control Value Changed event (from the refresh in the connector inspector to the refresh control on the document outline (left)) 
[add `UIRefreshControl` to prototype to simulate async loading of the feed]
- add a reference to the feedImageContainer (IBOutlet) in FeedImageCell
- add a private extension to UIView for the shimmering animation
- startShimmering in awakeFromNib and prepareForReuse
- connect the image container outlet
- return inmediately in fadeIn to see the animation
- after the animation is done stopShimmering (add completion parameter to the animation)
- change withDuration: 0.35, delay: 1.25
[add shimmering animation while loading Image in the prototype app]

(on the EssentialFeed project)
- create FeedViewControllerTests file
T) test_init_doesNotLoadFeed
- create a sut with a loader
- assert loader.loadCallCount to be 0 
- create the FeedViewController
- create LoaderSpy (private(set) loadCallCount = 0) 
- create the instance of the loaderSpy (loader)
- add init(loader:) to the FeedViewController that does nothing (using the loader spy type with namespace)
[Does not load feed on init (before the view is loaded)]
T) test_viewDidLoad_loadsFeed
- create a loader (spy), create a sut with that loader
- invoke loadViewInNeeded in the sut (now FeedViewController must inherit from UIViewController)
- assert that loader.count is 1
- change the current FeedViewController initializer to be convenience
- add the call to the loader in viewDidLoad: loader?.load()
- add a private reference to the loader in the FeedViewController (optional)
- add the load function to the spy and increment the count 
[load feed on view did load]
- change type of the loader to be FeedLoader 
- import EssentialFeed 
- link the EssetialFeed to the EssentialFeediOS
- project -> EssentialFeediOS -> Frameworks and Libraries -> + -> EssentialFeed.framework
- fix production and spy code
[replace `FeedViewControllerTests.LoaderSpy` references in the production types with the production `FeedLoader` protocol abstraction]
- create a makeSUT 
- track for memory leaks (add target membership to the XCTestCase+MemoryLeakTracking file to EssentialFeediOSTests)
[extract system under test (sut) creation to a factory method]
T) test_pullToRefresh_loadsFeed
- create a sut and a spy
- call loadViewIfNeeded
- make FeedViewController inherit from UTableViewController
- iterate through all of the targets and actions in the refresh control for the control event .valueChange and perform the action
- create a refresh control (asign it to the already existing optional refreshControl) and add a target action for the valueChanged event
- create a private load function (@objc)
- move the loader logic there and call load in viewDidLoad
- move the code to simultate the pull to refresh to a UIRefreshControl private extension called simulatePullToRefresh
- execute the code twice and expect 2 and 3 loadCallCounts
[extract pull to refresh simulation into a reusable extension on `UIRefreshControl`]
T) test_viewDidLoad_showsLoadingIndicator
- create a sut 
- call loadViewIfNeeded
- assert that the refreshControl isRefreshing is true
- call beginRefreshing (refreshControl) in viewDidLoad
[show loading indicator on view did load]
T) test_viewDidLoad_hidesLoadingIndicatorOnLoaderCompletion
- create a sut and a loader
- call lvin
- and make the spy complete (completeFeedLoading)
- add completeFeedLoading to the spy 
- capture completion blocks in a private completions var
- move loadCallCount to a computed var using the completions array count
- call endRefreshing in the load completion closure
- add weak self in the closure
[hide loading indicator on loader completion]
T) test_pullToRefresh_showsLoadingIndicator
- create a sut 
- call simulate pull to refresh 
- assert that isRefresing is true
T) test_pullToRefresh_hidesLoadingIndicatorOnLoaderCompletion
- create a sut and loader
- call simulate 
- complete loading 
- assert that isRefreshing is false
[hide loading indicator on pull to refresh]
- rename the tests that mention the pull to refresh to userInitiatedFeedReload
- create a simulateUserInitiatedFeedReload (DSL = Domain Specific Languague) as a private extension of the FeedViewController
[decouple tests from specific UI controls for user initiated reloads with test-specific DSL method]
- add isShowingLoadingIndicator (DSL) to the FeedViewController
[decouple tests from specific UI loading indicators with test-specific DSL method]
- unify loader tests to test_loadFeedActions_requestFeedFromLoader
- unify loading indicator tests to test_loadingIndicator_isVisibleWhileLoadingFeed
- add the index of the completion block to run the correponding completion blocks (e.g. at: 0)
- test should fail now 
- move the beginRereshing to the load method 
- add assertion names e.g. "Expected loading indicator once view is loaded" "Expected no loading indicator once loading is completed"
[combine relevant tests to eliminate temporal coupling bugs]
- move the FeedViewController to production
- set the correct access control
[move `FeedViewController` to production target]
 ```
 
### 4) Effectively Test-driving MVC UI with Multiple Views/Models/State, Efficiently Loading/Prefetching/Cancelling Image Requests, Inside-Out vs. Outside-In Development, and Identifying the Massive View Controller Anti-pattern by Following Design Principles
```
T) test_loadFeedCompletion_rendersSuccessfullyLoadedFeed
- call loadViewIfNeeded
- assert that the sut numberOfRenderedFeedImageViews is 0  
- add numberOfRenderedFeedImageViews DSL  
- (in this case use numberOfRows - feedImageSection (0))
- create an image0 (makeImage func with location, description and dafault url)
- then call completeFeedLoading with that image (change completeFeedLoading)
- expect 1 rendered image view TF
- add numberOfRowsInSection to return tableModel (FeedImage array) count
- in the load function set the tableModel with the received data (use result.get)
- and reload the table view TS
- in the test get a view with feedImageView(at:)
- add feedImageView(at:) DSL (use tableView.dataSource and cellForRowAt)
- cast the view as FeedImageCell
- create FeedImageCell (UITableViewCell)
- assert that the view is not nil
- assert that isShowingLocation is true
- assert that locationText is equal to the image0 location
- assert that descriptionText is equal to the image0 description
- add extension to the FeedImageCell to add those DSL
- add the view elements to the FeedImageCell (locationLabel = UILabel()) TF
- add cellForRowAt in sut (fill the cell with cellModel) TS 
- add more images (with all combinations) 
- to test many (4) TEST 0 TEST 1 AND TEST MANY 
- assert that the views are 4 
- move assertion of the cell to a helper function
- assertThat(sut, hasViewConfiguredFor: image0, at: 0)
- use this helper to check all cells TS
- add helper method assertThat(sut, isRendering: [])
[render loaded feed on successful load completion]
T) test_loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError
- loadViewIfNeeded
- completeFeedLoading with image0
- assert that sut is rendering image0
- simulate user reload
- complete with error
- assert that sut is still rendering image0 
- create completeFeedLoaderWithError(at:) TF
- change production code to switch the result TS 
[does not alter current feed rendering state on load error]
- change the test of the loading indicator to fail in the last one
- move the end refreshing outside the switch
- change switch with if let and result.get
- change error messages on loading indicator test
[hide loading indicator on both load error and success]
T) test_feedImageView_loadsImageURLWhenVisible
- create two images with different urls
- complete the loading with them
- check that loader loadedImageUrls is empty TS
- simulateFeedImageViewVisible(at:) (DSL on FeedViewController) 
- assert that loadedImageURLs is iqual to image0.url
- add the same for the second image TF
- in cell for row call imageLoader.loadImageData(from:) (not yet created) on cell for row
- add imageLoader of new type FeedImageDataLoader
- add the FeedImageDataLoader protocol 
- rename loader to feedLoader to give more context
- add it to the init method
- fix the makeSUT (pass the same spy)
- add LoaderSpy conformance to FeedImageDataLoader 
- change loadedImageURLs (private(set) var with empty array
- in loadImageData append the url TS
- segment the methods with MARK 
- rename completions to feedRequests
- rename loadCallCount to loadFeedCallCount
[load image URL when image view is visible]
T) test_feedImageView_cancelsImageLoadingWhenNotVisibleAnymore
- create two images
- loadViewIfNeeded
- completeFeedLoading with that images
- expect loader.cancelledImageURLs to be empty
- add it to the loader spy TS
- simulateFeedImageViewNotVisible(at:0) 
- expect cancelledImageURLs array has the url of the first image
- simulateFeedImageViewNotVisible(at:1)
- expect cancelledImageURLs array has the urls of the two images TF
- add that simulateFeedImageViewVisible now return the view (FeedImageCell)
- add discardableResult (to not break the other tests)
- add simulateFeedImageViewNotVisible 
- (get the view using simulateFeedImageViewVisible)
- (add a delegate and ask for the didEndDisplaying func)
- implement the didEndDisplaying cell func on production code
- add self to be the delegate of the tableView
- tell the image loader to cancel the request
- add cancelImageDataLoad(from url: URL)
- fix the spy 
[cancel image loading when image view is not visible anymore]
- add protocol FeedImageDataLoaderTask (func cancel())
- change the FeedImageDataLoader to return that task
- now the caller can store the tasks and cancel them (also tasks[indexPath]? = nil)
- tasks is a dictionary with key of type IndexPath
- fix the spy 
- add TaskSpy (private struct) conforming to the FeedImageDataLoaderTask
- with a cancelCallBack (in this call back we increment the count as before)
[extract `CancelImageDataLoad(from: URL)` method from `FeedImageDataLoader` protocol into a new `FeedImageDataLoaderTask` protocol that represents a task that can be cancelled. This way, we respect the Interface Segregation Principle and `FeedImageDataLoader` implementations are not force to be statefull]
T) test_feedImageViewLoadingIndicator_isVisibleWhileLoadingImage
- load two images (any)
- get the images with simulateFeedImageViewVisible(at:0)
- assert that isShowingImageLoadingIndicator is true for the two images 
- then completeImageLoading(at: 0)
- assert that isShowingImageLoadingIndicator is false for the first and true for the second
- then completeImageLoading(at:1)
- assert that both are false now
- implement the completeImageLoading(with:at:) and completeImageLoadingWithError(at:) in the spy
- add isShowingImageLoadingIndicator DSL to the FeedImageCell (isShimmering)
- add feedImageContainer to FeedImageCell
- add the shimmering extension to the UIView
- implement the shimmering on the cell for row func 
- add a callback to the imageLoader with a result (data or error) 
- stop the shimmering on the callback
- fix the spy 
- add imageRequests (url, completions)
- refactor loadedImageURLs to get the info from imageRequests
- use the imageRequest in the completeImageLoading
- and NSError in the completeImageLoadingWithError TS
[feed image view loading indicator is visible while loading image]
T) test_feedImageView_rendersImageLoadedFromURL
- loadViewIfNeeded
- completeLoading with two images
- get the views with simulateFeedImageViewVisible(at: 0) and 1
- assert that view0 and view1 renderedImage's are .none
- create a imageData0 (using UIImage pngData)
- completeImageLoading(with: imageData0, at: 0)
- assert that view0 rendered image is equal to imageData0 and view1 is .none
- repeat the step and assert both images are equal to the ones provided
- add renderedImage DSL to the FeedImageCell (using pngData)
- add feedImageView to the cell
- add extension make(withColor:) to UIImage
- implement cell for row code
- set the image to nil before start loading (avoid issues when reusing cells) 
- in the completion block get the data from the result and set the image 
[render loaded images from URL]
T) test_feedImageViewRetryButton_isVisibleOnImageURLLoadError
- repeat the same principle with a isShowingRetryAction
- add the DSL isShowingRetryAction to FeedImageCell (feedImageRetryButton)
- add feedImageRetryButton to FeedImageCell
- in cell for row it start hidden 
- and visible if it couldn't get data from result (isHidden = (data != nil))
[feed image view retry button is visible on image url load error]
T) test_feedImageViewRetryButton_isVisibleOnInvalidImageData
- complete loading with an image
- get the view of the cell 
- assert that isShowingRetryAction is false
- simulate load refresh
- complete image loading with an invalid image
- assert that isShowingRetryAction is true
- refactor the code in production to check for the converted image 
[feed image view retry button is visible on invalid loaded image data]
T) test_feedImageViewRetryAction_retriesImageLoad
- create two images (makeImage) with distinct urls ("http://url-0/1.com")
- complete with those images
- get the views with simulateFeedImageViewVisible 
- assert that the loaded urls are the ones provided
- completeImageLoadingWithError(at:0) and 1
- check again for only two urls requests
- view0 simulateRetryAction  
- assert loadedImageUrls are now three urls in order (image0.url, 1, 0) 
- view1 simulateRetryAction
- assert loadedIamgeUrls are now the four urls
- create simulateRetryAction DSL in FeedImageCell (simulateTap)
- create simulateTap extension on UIButton (going trough all target actions)
- in cell for row add to the cell the onRetry code 
- add onRetry property to the cell (optional closure)
- configure the button with a target action (retryButtonTapped) pointing to self and perform the onRetry closure
- add the same logic to load the image (copy and paste)
- refactor duplicate code (using new loadImage) 
[retry failed image load on retry action]
T) test_feedImageView_preloadsImageURLWhenNearVisible
- create two distint images 
- completeFeedLoading
- assert loadedImageURLs is empty
- simulateFeedImageViewNearVisible(at:0)
- assert loadedImageURLS has the first image url
- add simulateFeedImageViewNearVisible(at row: Int) DSL to sut (using prefetchDataSource prefetchRowsAt)
- change FeedViewControler implementation - make the prefetchedDataSource deleget to be self
- conform to UITableViewDataSourcePrefetching
- implement prefetchRowAt indexPath
- going through all of the indexPaths use the loader to load the images
[preload image URL when image view near visible]
T) test_feedImageView_cancelsImageURLPreloadingWhenNotNearVisibleAnymore
- very similar to the other test but with simulateFeedImageViewNotNearVisible (and cancelledImageURLs)
- add simulateFeedImageViewNotNearVisible DSL to sut (using simulateFeedImageViewNearVisible and cancelPrefetchingForRowsAt)
- add the implementation for the cancelPrefetchingForRowsAt (cancel the task) 
- hold the task in the prefetchRowsAt
- create a helper cancelTask(forRowAt indexPath)
- use it in both places
[cancel image URL preloading when image view is not near visible anymore]
```

### 5) Refactoring Massive View Controllers Into Multiple Tiny MVCs + Using Composers & Adapters to Reduce Coupling and Eliminate Redundant Dependencies

```
- reorder file structure
- (in the FeedViewController file)
- add FeedRefreshViewController (inherited from NSObject because of target action)
- add a private set lazy property view (UIRefreshControl) with a load action configured (cut the existing load func)
- add a private let feedLoader property (injected it in init)
- add an onRefresh closure to send the feeds back to the client when finish loading
- remove the feedLoader property and  
- add a refreshController to the FeedViewController (configure it in init)
- in viewDidLoad set the refreshControl to be the view of the refreshController
- and set the onRefresh closure (update the tableModel)
- add a property observer to the tableModel to call a reload on the table 
- the load function is called on the refreshController now (change the name to refresh)
- move FeedRefreshViewController to its own file (controllers folder)
[extract `UIRefreshControl` creation/configuration and refresh logic with `FeedLoader` to the new `FeedRefreshViewController`]
- add FeedImageCellController (final public class)
- copy and paste cell creation func rename it to view(model:) 
- add private task property (to keep the running task)
- add imageLoader (using creation injection)
- also inject the model (creation)
- use this cellController in cellForRow and invoke its view method
- add cellControllers (dictionary with indexPaths) (to keep reference to them)
- set the corresponding to nil in didEndDisplaying acording to the indexPath
- add a deinit to cancel the task if any TS
- remove cancel task call in didEndDisplaying (no more needed)
- create a cellController also in prefetchRowsAt
- in cancelTask set the controller of the correponding indexPath to nil (rename to removeCellController)
- use it in didEndDisplaying
- add cellController(forRowAt:) and use it cellForRow and prefetchRowsAt
- add a prelod method in the new controller accepting a cellModel (use it in prefetchRowsAt)
- remove old tasks - move FeedImageCellController to its own file
[extract `FeedImageCell` creation/configuration and image loading logic with `FeedImageDataLoader` to the new `FeedImageCellController`]
- discuss solution using a factory (unneded dependency)
- change tableModel to be an array of FeedImageCellController (to not depend any more on FeedImage or FeedImageDataLoader)
- in the onRefresh we can map the feed into FeedImageCellControllers
- delete old cellControllers array
- change the cellController(forRowAt:) to return the tableModel item (cellController) for that row
- rename removeCellController to cancelCellControllerLoad (now we perform cancelLoad)
- replace the deinit with cancelLoad TS
- now we can remove the reference to the imageLoader and move the cell creation to the initializer (FeedViewController)
- and use directly the imageLoader
- add FeedUIComposer public final class (move the init there)
- refactor to a static func feedComposedWith(feedLoader:imageLoader:) that returns a FeedViewController
- remove the creation of the refreshController from the FeedViewController init
- received it instead from a dependency (only this one)
- remove public from conveninece init (no more needed, since the composer should be the only way of creating FeedViewControllers) 
- fix the tests 
- move FeedUIComposer to its own file (new Composers folder)
- make the composer initializer private
[extract dependency creation and composition logic from `FeedViewController` into the new `FeedUIComposer`]
- add private static func adaptFeedToCellController(forwardingTo controller: loader:) -> ([FeedImage]) -> Void
- [FeedImage] -> Adapt -> [FeedImageCellController] 
[extract adapter pattern into a separate function to clarify intent]
```

### 6) MVVM: Reducing Boilerplate, Shifting Reusable Presentation Logic from Controllers into Cross-Platform (Stateful & Stateless) ViewModels, and Decoupling Presentation from UI Frameworks with Swift Generics
```
- (in FeedRefreshViewController file)
- create new FeedViewModel (final class) move init and refresh (rename to loadFeed and objc) 
- remove the references to the view (e.g. beginRefreshing)
- add onChange closure (to notify the changes - send the viewModel reference)
- add State enum (pending, loading, loaded(with feed), failed)
- add private property state (initialized at pending)
- when a state change we notify with the onChange closure
- add state transitions
- add state accessor isLoading computed var (using switch)
- add state accessor to the feed (using switch - loaded case)
- in FeedRefreshViewController remove reference to FeedLoader
- replace it be a viewModel (create it in the init method)
- in the refresh set the onChange callback 
- refactor it to receive a viewModel
- when the viewModel isLoading the view can begin refreshing
- also to endRefreshing
- check if there is a feed and pass it forward
- finally tell the viewModel to load the feed TS
- add bind function (with this binding code accepts UIRefreshControl) - call it in the view creation
- add the target action binding there too (now returning a UIRefreshControl)
- use it in view creation closure 
- change name to binded and remove the creation closure (one liner)
- move viewModel to its own file (Models folder)
- move the viewModel creation and injection to the composer
- remove onRefresh closure from FeedRefreshViewController (it only forward the info)
- and add it to the FeedViewModel (change name to onFeedLoad)
- remove feed state loaded (in loadFeed func)
- forward the feed to the onFeedLoad closure observer
- after finish loading update the state to pending (remove the loaded and fail states)
- use isLoading as a state, private(set) var (with a property observer) - remove old state
- change the adaptFeedToCellController to the feedViewModel.onFeedLoad
- remove the EssentialFeed import from FeedRefreshViewController (no more state management)
[Move `FeedLoader` loading state management to `FeedViewModel`. Now, the `FeedRefreshViewController` acts as a binder between the `View` and the `ViewModel`]
- now the FeedViewModel holds state but it can be eliminted by
- adding an onLoadingStateChange (closure that receive a bool) and pass the state transitions directly 
- update the controller (weakify only the view)
- add typealias Observer (with generic type) to clarify the intent (use it on both observers)
[remove mutable state from `FeedViewModel`. The `FeedViewModel` only needs to forward state changes, so state is only transient]
- add a FeedImageViewModel (repeat the steps)
- add imageTransformer (closure recieving Data and returning generic type optional Image)
- add imageTransformer closure injection to the init method
- fix the view model - fix the composer - fix the controller
[move `FeedImageDataLoader` loading state management to `FeedImageViewModel`. Now the `FeedImageCellController` acts as a binder between the `View` and the `ViewModel`]

[decouple `FeedImageViewModel` from `UIKit` by creating a transformation closure that converts an image `Data` value into a generic `Image` type. When composing wiht a UIKit user interface, we inject a closure to transform the image `Data` into `UIImage`]
- remove EssentialFeed import from the FeedViewController (no longer needed)
[remove `EssentialFeed` module import from `FeedViewController` file since it does not depend on any `EssentialFeed` component]
```

### 7) MVP: Creating a Reusable and Cross-Platform Presentation Layer, Implementing Service Adapters, and Solving Cyclic Dependencies & Memory Management issues with the Proxy Pattern

```
- the presenter has a reference to the view (through a protocol)
- add Feed Presentation folder (move FeedViewModel, FeedImageViewModel)
- add FeedPresenter (copy code of FeedViewModel)
- add FeedView protocol with two funcs display(isLoading), display(feed) 
- replace the observable properties with a view property (FeedView) (update code)
- the protocol has two methods (violation of Interface Segregation Principle)
- break it down into two protocol (FeedLoadingView, FeedView) add a loadingView (update code)
- rename view property to feedView and add loadingView
- make FeedRefreshViewContoller conform to FeedLoadingView
- implement the display method 
- rename binded to loadView (create the view and set the action)
- replace viewModel with feedPresenter
- update the composition  (presenter loadingView is now the refreshController)
- move the adapter code to a new private final class FeedViewAdapter (conforming to FeedView) 
- tranforms the feed into FeedImageCellControllers and set them to the FeedViewController tableModel
- this new class has to dependecies controller (make it weak) and imageLoader
- remove the view models TF -> memory leaks!
- make the reference to the loadingView weak (change FeedLoadingView protocol to be class (now AnyObject) conforming) TS
[add `FeedPresenter` holding feed loading presentation logic (loading state and loaded feed)]
- we could use trick like (AnyObject & FeedLoadingView) but still we'll leaking composition details 
- create WeakRefVirtualProxy (wiht generic type T be AnyObject)
- crate an extension to conform to FeedLoadingView protocol 
- constraint conformance of T to FeedLoadingView to have a double check by the compiler
[move memory management to Composer layer. The `FeedPresenter` shouldn't have to know or handle their dependencies lifetime]
- remove the FeedViewModel
[remove unused `FeedViewModel` (it was replaced by the new `FeedPresenter`)]
- the presenters must translate model values into view data so
- add FeedLoadingViewModel struct to replace the boolean of the protocol FeedLoadingView
- this way we can also add new properties and don't brake the protocol
- add also FeedViewModel (update code)
[add Presentable View Models as pure data to clarify communication between Presentation and UI]
- in MVP the 'views' hold a reference to the presenter (in our case it is only use to load the feed) 
- in this case we can change the presenter with an injected loadFeed function (update composition)
[decouple `FeedRefreshViewController` from the concrete `FeedPresenter` dependency with a closure]
- the presenter can also don't need to communicate with domain services directly 
- this can be done via an adapter that receives the events of the view and talks back to the presenter
- after communitating with the domain services
- remove the FeedLoader dependency from FeedPresenter
- add didStartLoadingFeed
- add didFinishLoadingFeed(with feed)
- add didFinishLoading(with error) only communicate that it finished loading with no feed
- in the FeedUIComposer file add FeedLoaderPresentationAdapter
- with two dependencies feedLoader and presenter
- implement the loadFeed func
- update the composition (presentationAdapter)
[decouple `FeedPresenter` from `FeedLoader` with an adapter in the Composition layer]
- another change that it can be made is to use a protocol instead of using the loadFeed closure
- add FeedRefreshViewControllerDelegate with didRequestFeedRefresh
- and inject the delegate in the init method (constructor injection)
- make the adapter class implement the delegate protocol 
[replace Closure event handler with delegate Protocol to demonstrate different composition approaches]
- in MVP the presenter must hold references to the views protocols
- change the views to be constructor injected (init) no need to be optionals anymore
- in the composition there is a catch 22 problem now
- make the FeedLoaderPresentationAdapter be property injected (presenter)
[move from property injection to constructor injection in the `FeedPresenter` to guarantee its instances have access to its dependencies at all times]
- repleace old FeedImageViewModel with new FeedImagePresenter (repeat the steps)
- viewModel now holds only data
- the FeedImagePresenter receives commands from the adapter FeedImageDataLoaderPresentationAdapter 
- (handles the communication with the domain services) and forward it its view
- with all the information needed encapsulated in the view model (FeedImageViewModel)
- the commands are didStartLoadingImageData, didFinishLoadingImageData(with error and with data).
- the FeedImageCellController receives this data via the display method of the FeedImageView protocol 
- the FeedImageCellController also talks to its delegate, the adapter, with the messages:
- didRequestImage, didCancelImageRequest (could be named requestImage instead
```

### 7) Storyboard vs. Code: Layout, DI and Composition, Identifying the Constrained Construction DI Anti-pattern, and Optimizing Performance by Reusing Cells
```
- create a storyboard file Feed and copy the prototype layout
- remove navigation controller and navigation item (from FeedViewController)
- make it the initial view controller
- crate a Feed assets catalog (drag and drop the images)
- check for connections inspector (delete the failing ones)
- also for the cell
- add the retry button in the image container (as big as the superview)
- use the caracter arrow set font (60) text color (white)
[add Feed storyboard and assets with layout from prototype]
- instanciate the FeedViewController from the storyboard
- get the storyboard and the bundle (FeedViewController.self)
- instanciate the feedViewController (instanciateInitialViwController) force cast is ok
- change from constructor to property injection in FeedViewController TS
[instanciate `FeedViewController` from Feed storyboard]
- we are now setting the refresh control in code and in the storyboard
- remove the creation of refresh controller in FeedRefreshViewController
- set the refresh controller view as an IBOutlet
- change refresh to be an IBAction 
- now we need to connect FeedRefreshViewController with its view in storyboard
- add an object to the FeedViewController set the type as FeedRefreshViewController
- connect the FeedRefreshViewController view and refresh (valueChange) to the refresh control
- remove refresh controller creation from composition 
- get a reference from the feedController and use property injection for the delegate (update the refresh controller) force unwrap is ok
- remove the setting of the refresh control in FeedViewController
- change the property to be an IBOutlet (conect it in storyboard) TS
[move `FeedViewController` + `FeedRefreshViewController` composition (instantiation and configuariton) to Storyboard]
- since the composition is happening in the storyboard we can get rid of the refresh controler
- move the FeedLoadingView protocol conformance to the FeedViewController (with the implementation)
- move the delegate rename it to FeedViewControllerDelegate (replace the refreshController with delegate)
- move the refresh (IBAction) can be set to private (fix code)
- remove the refresh controller object from storyboard 
- conect the refresh action of the controller to the refresh control (valueChange)
- update the composition in the FeedUIComposer 
- delete the FeedRefreshViewController
[merge `FeedRefreshViewController` with `FeedViewController` since the `UIRefreshControl` creation and configuation now lives in the storyboard]
- mover the prefetchDataSource settings to the storyboard 
[move tableView.prefetchDataSource setup to the storyboard]
- insted of instanciating cell we can deque them (need a reference to the table view)
- use method injection (in) to recieve the table view and dequeue a reusable cell
- fix code in FeedViewController 
- change the property of the FeedImageCell be IBOutlets private(set) public var
- and retryButtonTapped IBAction
- perform the connections in storyboard (tapUpInsideEvent) TS
- in cancelLoad we need to release the cell because other controller may be using the same cell
T) test_feedImageView_doesNotRenderLoadedImageWhenNotVisibleAnymore
- setup test with a feed with one image
- simulateFeedImageViewNotVisible at position 0
- complete the image loading with any image data (red)
- expect that the view rendered image be nil (renderedImage)
- add return the view to the simulateFeedImageViewNotVisible (@dicardableResult)
- make the fix (use helper function releaseCellForReuse)
- create the helper method anyImageData
- add assertion message "Expected no rendered image when an image laod finishes after the view is not visible anymore"
[reuse table view cells from storyboard configuration]
- create helper (UITableView extension) dequeueReusableCell with generic  
- use the class property to have information of the type
- move extension to its own file (UITableView+dequeueReusableCell)
[add UITableView helper to dequeue typed cells by class name]
- add animation to fade in the image (duration 0.25 )
- add extention to UIImageView setImageAnimated (instead of if use guard)
- move the extension to new file (UIImage+Animations)
[display image with animation]
```

### 8) Creating, Localizing, and Testing Customer Facing Strings in the Presentation Layer + NSLocalizedString Best Practices
```
In FeedViewControllerTests
T) test_feedView_hasTitle 
- create sut and call loadViewIfNeeded
- assert that title of the sut is "My Feed" TF
- add the title in the FeedViewController (viewDidLoad)
[set `FeedViewController` title]
- in MVP the presentation strings should be done by the presenter 
- and in MVVM by the view model
- set the title with a FeedPresenter static computed var (title) add it to Presenter
[move title string creation from `FeedViewController` to `FeedPresenter` - in MVP, presentation data should be created by Presenters]
- move the title configuration to the composer 
- (the FeedViewController don't know about the FeedPresenter)
- can be pass as a property of the viewModel also
[move title configuration from `FeedViewController` to the `FeedUIComposer` - the View Controllers can be agnostic of Presenters if we move the configuration to composers]
- extract the FeedViewController configuration and creation to a factory method
- makeWith (delegate, title) (static func extension of FeedViewController)
[extract the `FeedViewController` creation and configuration into a factory method]
- in the title test add a bundle (FeedViewController.self)
- get the localizedString for key "My Feed" value nil table nil
- asssert that the sut.title is equal to the localizedTitle TS
- we can use the NSLocalizedString with comments but for test is ok the this way
- if the localizedString does not found the String it returns the key
- that's why the test were passing
- but this is not recommended (keys should be keys)
- change to FEED_VIEW_TITLE (can pass a default value in the value param)
- create a Feed.strings (Feed Presentation folder)
- change table to be "Feed" TF
- update production code (FeedPresenter)
- use NSLocalizedString (bundle FeedPresenter.self) ommit value 
- comment "Title for the feed view" TS
- but becuase the two places return the key when not finding the localized string!
- add a localizedKey variable and an assertion to compare it to the title with error:
- "Missing localized string for key: localizedKey"
- add "FEED_VIEW_TITLE" = "My Feed"; to the file TS
[Localize feed view title string]
- add localized helper function (pass a key and look for localized string for that key)
- fire an assertion failure if it cannot find one. also return the string
- "Missing localized string for key: key in table: table" TS
- try removing the key pair in the table and it fails
- move helper to FeedViewControllerTests+Localization (Helpers Folder)
[create test helper to find missing localized strings]
- rename FeedViewControllerTests to FeedUIIntegrationTests
- move helpers to EssentialFeediOSTests/Feed UI/Helpers
- EssentialFeediOSTests/Feed UI/FeedUIIntegrationTests
[rename `FeedViewControllerTests` to `FeedUIIntegrationTests` since we are testing the composition of multiple UI components in integration]
- localize the Feed.string by pressing the Localized button in the right panel
- default languague is english TS
[Localized `Feed.strings` file]
- in the project configuration add support Locaclization (+) for portuguese (pt-BR)
- now the Feed.string has multiple versions
- translate the string (Meu Feed) TS
[add Portuguese (pt-BR) localization]
- add support for greek 
- tranlate the string "To Feed ponele" TS
[add Greek (el) localization]
- create the FeedLocalizationTests 
- look for all localization bundles in the presentation bundle 
- look for all key in the localization bundles 
- go through all bundles and localized keys
- the static localization should live in the presentation layer 
- the UI layer should only renders the info passed to it
[add localization test to guarantee all localized key have tranlations in all supported localizations]
```

### 9) Decorator Pattern: Decoupling UIKit Components From Threading Details, Removing Duplication, and Implementing Cross-Cutting Concerns In a Clean & SOLID Way
```
- all UIkit code must run in the main thread
T) test_loadFeedCompletion_dispatchesFromBackgroundToMainThread
- create a sut and call leadViewIfNeeded
- create an exp "Wait for feed completion"
- dispatch the feed loading completion to a diferent queue (global() async) fulfill exp
- fix the crash with a dispatch to the main queue (tableView reloadData)
- check if the Thread isMainThread (to call reloadData directly)
- fix other crash with guard Thread.isMainDispatch else DispatchQueue.main.async (self.display..)
- fix weak failing test 
[dispatch background feed completion to main thread before updating the UI since UIKit is not thread safe]
- move the threading check one level above (presenter layer) with the guard aproach 
[move main thread dispatch to the Presenter]
- presenter is platform agnostic should not leak UIkit details
- move the threading handling one level aboce (composition layer)
- create MainQueueDispatchDecorator (decoratee: FeedlLoader)
- check to see if we are in the main thread to complete directly or otherwise to the main 
- decorate the feedLoader
[move main thread dispatch to the Composition layer with a Decorator]
- make MainQueueDispatchDecorator be generic with an extension
- add a dispatch completion func to the decorator main class
- use it in the extension
- replace the if else with a guard statement
[make `MainQueueDispatchDecorator` generic]
T) test_loadImageDataCompletion_dispatchesFromBackgroundToMainThread
- create a sut, loadViewIfNeeded, completeLoading with an image
- simulateFeedImageViewVisible
- create exp "Wait for background queue work"
- dispatch completeImageLoading anyImageData (fulfill exp)
- wait for exp (1.0)
- add extension to decorate the FeedImageDataLoader 
[dispatch background feed image data completion to main thread before passing result to the UI components. Threading is dealt with a Decorator in the Composition layer]
- move MainQueueDispath and extension to its own file (Composers folder)
[move `MainQueueDispatchDecorator` to separate file]
- move composition helpers to separate files (WeakRefVirtualProxy, FeedViewAdapter etc)
- create makeFeedViewController static func also
[...]
```

### 10) Test-driven Approach to Effectively Dealing with Legacy Code (Code With No Tests!) + Extracting Cross-platform Components From a Platform-specific Module
```
- create a group Feed Presentation (in EssentialFeedTests) cross-platform module
- create FeedPresenterTests
- instead of moving the FeedPresenter the idea is to create a new FeedPresenter
- use the old FeedPresenter as a guide (check list for what to test)
T) test_init_doesNotSendMessagesToView (always start with the degenerate case)
- assert that view.messages is empty (XCTAssertTrue) "Expected no view messages"
- create the view instance (ViewSpy holding the messages)
- create a FeedPresenter with that view (discard the result) 
- message holding Any 
- create the new FeedPresenter with the init receiving Any as the view type
[`FeedPresenter` does not send messages to view on init]
- create a factory method makeSUT (returning the view and the sut) with memory leak tracking
[extract system under test creation to a test factory method]
T) test_didStartLoadingFeed_displaysNoErrorMessage
- add an assertion that the view.messages should be equal to [.display(.noError)]
- that is copying the message from the already existing code
- create a Message enum representing all of the messages sent to the view
- in this case it is the display with an optional string assosiated value (errorMessage)
- update the assertion with the new interface 
- make the Message be equatable to solve the compiler error 
- now invoke the event in the sut (add it to the FeedPresenter - empty) TF
- then copy the code from the existing FeedPresenter - follow the compiler errors
- copy the errorView (rename view to errorView)
- copy the FeedErrorView and the FeedErrorViewModel (only the part needed) TF
- refactor the makeSUT
- make the spy implement the FeedErrorView 
- append the message to the messages array when received
- now the messages need to be a var (but with private setter) TS
[`FeedPresenter` displays no error on `didStartLoadingFeed`]
T) rename to test_didStartLoadingFeed_displaysNoErrorMessageAndStartsLoading
- add the message display isLoading to the array of messages in the assertion TF
- repeat the procedure of copy the origin code to the new FeedPresenter (only needed things) TF
- use the same spy and conform now also to the FeedLoadingView protocol TS
[`FeedPresenter` displays loading on `didStartLoadingFeed`]
- the order of the messages is not important but if when change the order the test will fail
- change the messages to be a Set instead (convert it to Hashable)
[make massages Array a Set to make test more permissive since we don't care about order. (Changing order should not break the tests!)]
T) test_didFinishLoadingFeed_diplaysFeedAndStopsLoading
- create sut and view 
- finish loading with a feed (use uniqueImageFeed)
- assert that the mssages are display feed and display is loading false
- create new case in messages (import EssentialFeed)
- there is a problem: FeedImage is not hashable (change it to be hashable) TF
- add implementation of didFinishLoadingFeed(with:)
- copy the implementation from the origin code
- follow the compiler adding only what it is missing
- add the comformance and the implementation to the spy
[`FeedPresenter` displays feed and stops loading on `didFinishLoadingFeed`]
T) test_didFinishLoadingWithError_displaysLocalizedErrorMessageAndStopLoading
- repeat the procedure
- finish loading with an error (anyNSError)
- display error message localized "FEED_VIEW_CONNECTION_ERROR"
- copy the localized method use in the integration tests
- use the FeedPresenter to create the bundle
- add the didFinishLoadingFeed (empty) TF
- copy all the needed parts TF
- the Feed.strings file is in another module
- create a new one, localized in all languages and bring the translations TS
[`FeedPresenter` displays localized error message and stops loading on `didFinishLoadingFeedWithError`]
T) test_title_isLocalized
- assert that the FeedPresenter title is equal to the localized "FEED_VIEW_TITLE"
- add an empty title
- only paste code if we see a failing test
[add localized `FeedPresenter.title`]
- move files to their own files in production (new group Feed Presentation)
- first the FeedPresenter (change the accessibility)
- move the Feed.string file (change the target membership to EssentialFeed)
[move prod types to the EssentialFeed production module]
- move type to their own files 
- remove old files from the EssentialFeediOS   
- import module fix error witht the help of the compiler (running the tests)
- import EssentialFeed to FeedLocalizationTests and to FeedUIIntegrationTests localized extension
[replace `FeedPresenter` from iOS module with the `FeedPresenter` from the cross-platform EssentialFeed module]
- move the FeedLocalizationTests to the EssentialFeedTests group (change target membership to EssentialFeedTests)
- remove the empty group Feed Presentation
[move `FeedLocalizationTests` to cross-platform EssentialFeed module]
- move FeedImagePresenter and FeedImageViewModel to the EssentialFeed module as well
```

## FOURTH MODULE - MAIN

### 1) Feed Image Data Loading and Caching with URLSession/CoreData + Composing Modules Into a Running iOS Application with Xcode Workspaces
```
- move FeedImageDataLoader to the EssentialFeed module (Feed Feature group) 
- implement RemoteFeedImageDataLoader and LocalFeedImageLoader
- add RemoteFeedImageDataLoaderTests
T) test_init_doesNotPerformAnyURLRequest
- assert that the client requestedURL is empty
- create a client (HTTPClientSpy) and a sut (RemoteFeedImageDataLoader)
- remote init with the client (Any)
- create makeSUT helper function with memory leak tracking
[RemoteFeedImageDataLoader does not perform any URL request]
T) test_loadImageDataFromURL_requestsDataFromURL
- perform loadImageData(from:) with a created url on sut
- assert that the requested urls is iqual to that url
[RemoteFeedImageDataLoader requests data from URL on `loadImageDataFromURL`]
T) test_loadImageDataFromURLTwice_requestsDataFromURLTwice
- repeat the same procedure twice so the array of requestedURLs has two urls
[RemoteFeedImageDataLoader requests data from URL twice on calling `loadImageDataFromURL` twice]
T) test_loadImageDataFromURL_deliversErrorOnClientError
- create the expect sut to completeWith when action helper
- use the FeedImageDataLoader.Result in the RemoteFeedImageDataLoader loadImageData completion
- expect the sut to complete with failure (with created NSError) when client complete with that error
[RemoteFeedImageDataLoader.loadImageDataFromURL delivers error on client error]
T) test_loadImageDataFromURL_deliversInvalidDataErrorOnNon200HTTPResponse
- create client complete withStatusCode data at (use HTTPURLResponse) 
- create "failure" helper to convert RemoteFeedImageDataLoader.Error into FeedImageDataLoader.Result failure result
[RemoteFeedImageDataLoader.loadImageDataFromURL delivers invalid data error on non-200 HTTP response]
T) test_loadImageDataFromURL_deliversInvalidDataErrorOn200HTTPResponseWithEmptyData
- complete withStatusCode 200 and emptyData
[`RemoteFeedImageDataLoader.loadImageDataFromURL` delivers invalid data error on 200 HTTP response with empty data]
T) test_loadImageDataFromURL_deliversReceivedNonEmptyDataOn200HTTPResponse
- modify production code to check for 200 case and empty data
[`RemoteFeedImageDataLoader.loadImageDataFromURL` delivers non-empty received data on 200 HTTP response]
T) test_loadImageDataFromURL_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated
- add check for self not being nil in production code
T) test_cancelGetFromURLTask_cancelsURLRequest (URLSessionHTTPClientTests)
- add wrappers for the tasks (URLSessionTaskWrapper, HTTPTaskWrapper) 
- the wrapper has the name of the object that is wrapping + wrapper
- in the test break when the error is the canceled error (URLError.cancelled)
[Add HTTPClientTask so clients can cancel HTTP requests]
- refator "resultFor" helper in URLSessionHTTPClientTests
- add a tuple (values) with all the former values (data, response, error) and a taskHandler
[Extract duplicate error capturing logic by passing a taskHandler closure into the reusable `resultErrorFor` helper. Now, we can easily interact with the HTTP task as the request starts.]
- add a queue for handling the stub of the URLSession tests
[Synchronize access to global URLProtocolStub.stub with a private `DispatchQueue` to prevent data races]
- refactor the URLSessionHTTPClient
[Remove default URLSessionHTTPClient initializer parameter (dependency) as clients should be mindful about which `URLSession` instance to use. For example, clients may 
decide to use the `.shared` instance, but when testing we can inject a `URLSession` with an ephemeral configuration registered with the `URLProtocolStub` class. This way, we don't need to start/stop intercepting URL requests globally.]
T) test_loadImageDataFromURL_doesNotDeliverResultAfterCancellingTask
- modify HTTPTaskWrapper to prevent the completion when cancelling
[Cancelling the RemoteFeedImageDataLoader.loadImageDataFromURL cance…
…ls the HTTP client URL request]
[Cancelling the RemoteFeedImageDataLoader.loadImageDataFromURL cancels the HTTP client URL reques]
[Extract duplicate anyData helper into a shared scope]
[Extract duplicate HTTPClientSpy helper into a shared scope]
- move the RemoteFeedImageDataLoader (make it public and final)
[Move RemoteFeedImageDataLoader to production]
[Make RemoteFeedImageDataLoader conform to FeedImageDataLoader]
[RemoteFeedImageDataLoader.loadImageDataFromURL delivers connectivity error on HTTP client error]
[Refactor switch statement with mapError and flatMap chain]
[Remove @discardableResult attribute — FeedImageDataLoaderTask instances should be properly managed and never discarded.]
[Add RemoteFeedImageDataLoader end-to-end test to guarantee both the client (app) and server (backend) respects the API contract, so we can fetch image data from remote.]
[Extract duplicate base URL creation into a factory helper]
[Extract duplicate ephemeral HTTPClient creation into a factory helper]
[Extract duplicate HTTPURLResponse.statusCode == 200 validation into a `isOK` helper method]
[Move URLProtocolStub to separate file]
[Rename test case class to reflect the use case it refers to]
[Wait for URLProtocol to complete the URLRequest after a task has been canceled to avoid a test leak where the URLProtocol would be starting the request after the test finishes. This happens because cancelling a URLSessionDataTask won't immediately cancel the URLProtocol from receiving that request. So if we don't wait for it, there's a chance the URLProtocol request will run while another test is running and influence its result.]
[update use case]
- create LocalFeedImageDataLoaderTests (Feed Cache group)
[LocalFeedImageDataLoader does not message store upon creation]
T) test_loadImageDataFromURL_requestsStoredDataForURL
- add FeedImageDataStore protocol, add private struct Task that conforms to FeedImageDataLoaderTask
- add a store to the LocalFeedImageDataLoader conforming to the FeedImageDataStore
- refactor StoreSpy to collect receivedMessages (type Message)
[`LocalFeedImageDataLoader.loadImageData` requests stored data for URL from `FeedImageDataStore`]
T) test_loadImageDataFromURL_failsOnStoreError
- add expect sut toCompleteWith when 
- add Error to LocalFeedImageDataLoader 
- add failed helper (returns FeedImageDataLoader.Result with a LocalFeedImageDataLoader.Error.failed)
- add completions and and complete with to StoreSpy
[LocalFeedImageDataLoader.loadImageData fails on store error]
- add notFound helper (same idea as before)
- add complete with data to StoreSpy
- add mapError and flatMap to loadImageData of LocalFeedImageDataLoader
[LocalFeedImageDataLoader.loadImageData delivers not found error when store can't find image data for url]
T) test_loadImageDataFromURL_deliversStoredDataOnFoundData
- add complete handling for the flatMap call
[LocalFeedImageDataLoader.loadImageData delivers stored data when store finds image data for url]
T) test_loadImageDataFromURL_doesNotDeliverResultAfterCancellingTask
- refactor Task to receive a completion block which is stored in a completion variable that is optional, 
- then use the "complete with" function of the task instead of the received completion in the loadImageData
- the Task has a internal func preventFurtherCompletions that set the completion to nil when the 
- cancel function is invoked, thus when "complete with" is invoked there is no completion executed
[`LocalFeedImageDataLoader.loadImageData` does not deliver result after cancelling task]
T) test_loadImageDataFromURL_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated
- make self weak for the completion block of retrieve (store func) and return immediatelly if it is nil 
[LocalFeedImageDataLoader.loadImageData does not deliver result after instance has been deallocated]
[Move LocalFeedImageDataLoader and FeedImageDataStore to production]
T) test_saveImageDataForURL_requestsImageDataInsertionForURL
- add the insert method to the FeedImageDataStore (along with the InsertionResult)
- add insert case for Message in StoreSpy and the insert method
- add SaveResult and save func to LocalFeedImageDataLoader
[LocalFeedImageDataLoader.saveImageDataForURL requests image data insertion for url into the store]
[separate retrieval from insertion operations and types to clarify intent]
[rename test case class to clarify intent]
[extract FeedImageDataStoreSpy into a shared scope]
[Extract cache feed image data use case into the new CacheFeedImageDataUseCaseTests test case class]
T) test_saveImageDataFromURL_failsOnStoreInsertionError
- add expect sut to completWith when helper to CacheFeedImageDataUseCaseTests
- add SaveResult to LocalFeedImageDataLoader
- add insertionCompletions to FeedImageDataStoreSpy
[LocalFeedImageDataLoader.saveImageDataForURL requests image data insertion into store]
T) test_saveImageDataFromURL_succeedsOnSuccessfulStoreInsertion
- add completeInsertionSuccessfully to FeedImageDataStoreSpy
- modify LocalFeedImageDataLoader (save extension)
[LocalFeedImageDataLoader.saveImageDataFromURL succeeds on successful store insertion]
T) test_saveImageDataFromURL_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated
- add weak self to LocalFeedImageDataLoader save extension
[LocalFeedImageDataLoader.saveImageDataFromURL does not deliver result after instance has been deallocated]
- create new CoreDataFeedImageDataStoreTests
T) test_retrieveImageData_deliversNotFoundWhenEmpty
- create makeSUT
[CoreDataFeedStore.retrieveImageData delivers image data not found when empty]
T) test_retrieveImageData_deliversNotFoundWhenStoredDataURLDoesNotMatch
- add insert and localImage helpers
[CoreDataFeedStore.retrieveImageData delivers image data not found when store is not empty but there's no image with matching URL]
- add a new version of FeedStore.xcdatamodeld select the file and select Editor > Add Model Version
- name it FeedStore2 and add new "data" attribure (Binary Data)
- set it as the current version -> select FeedStore2.xcdatamodel file and select the version (FeedStore2) 
- add "data" also to ManagedFeedImage file (@NSManaged var data: Data?)
[add new FeedStore core data model version adding an optional Data property to the ManagedFeedImage]
[move CoreDataFeedStore implementation of the FeedImageDataStore protocol to production]
T) test_retrieveImageData_deliversFoundDataWhenThereIsAStoredImageDataMatchingURL
- add found helper to CoreDataFeedImageDataStoreTests
- implement insert and retrieve in the CoreDataFeedStore (FeedImageDataStore extension)
- add "first with url in context" helper to ManagedFeedImage
[CoreDataFeedStore.retrieveImageData delivers stored data when there's an image with a matching URL in the store]
T) test_retrieveImageData_deliversLastInsertedValue
[CoreDataFeedStore.retrieveImageData delivers last inserted value (overwriting previous values)]
[Add test to guarantee that CoreDataFeedStore side effects run serially to prevent unexpected behavior]
[remove unnecessary return statements]
- call map on image and assign the data in the transform closure
- call again map and save the context
[refactor procedural code into a chain of map operations]
[move CoreDataFeedStore implementation of the FeedStore protocol to separate file]
[Encapsulate CoreDataStore bundle creation into a centralized place to remove duplication and prevent mistakes]
[Clean up references to persistent stores on CoreDataStore.deinit to encapsulate the whole CoreData stack lifecycle within the `CoreDataStore` instance life time]
Add test to EssentialFeedCacheIntegrationTests
T) test_loadImageData_deliversSavedDataOnASeparateInstance  
- use the same approch with the feed test
[LocalFeedImageDataLoader in integration with the CoreDataFeedStore delivers items saved on separate instances, proving we correctly persist the data models to disk.]
[separate test scopes with better naming]
T) test_saveImageData_overridesSavedImageDataOnASeparateInstance
- use the same approch with the feed test
[LocalFeedImageDataLoader in integration with the CoreDataFeedStore overrides items saved by separate instances, proving we correctly manage the data models on disk.]
T) test_validateFeedCache_doesNotDeleteRecentlySavedFeed
- add validateCache(with:) helper function 
- add a ValidationResult and completion for the validateCache function of LocalFeedLoader
[LocalFeedLoader in integration with the CoreDataFeedStore does not delete recently saved items saved by separate instances when validating cache, proving we correctly manage the data models on disk.]
T) test_validateFeedCache_deletesFeedSavedInADistantPast 
- add currentDate parameter to makeFeedLoader helper
[LocalFeedLoader in integration with the CoreDataFeedStore deletes items saved in a distant past by separate instances when validating cache, proving we correctly manage the data models on disk.]
[Remove default LocalFeedLoader.validateCache completion closure as clients should be mindful about handling the result of the operation]
T) test_validateCache_failsOnDeletionErrorOfFailedRetrieval
T) test_validateCache_succeedsOnSuccessfulDeletionOfFailedRetrieval
- forwad the completion closure of validateCache (LocalFeedLoader) to the deleteCachedFeed (FeedStore)
[LocalFeedLoader.validateCache fails on deletion error of a failed retrieval]
T) test_validateCache_succeedsOnEmptyCache
[LocalFeedLoader.validateCache succeeds on empty cache]
T) test_validateCache_succeedsOnNonExpiredCache
[LocalFeedLoader.validateCache succeeds on non-expired cache]
T) test_validateCache_failsOnDeletionErrorOfExpiredCache
T) test_validateCache_succeedsOnSuccessfulDeletionOfExpiredCache
[LocalFeedLoader.validateCache fails on deletion error of a expired cache]
[Load NSManagedObjectModel instance lazily and cache it to prevent multiple `NSEntityDescriptions` claiming the same `NSManagedObject` model subclasses (This problem just generates warnings but could lead to undefined behavior in the future).]
- create a new project ios single view app: EssentialApp (single view app, storyboard, include tests)
- remove landscape (left and right)
[add empty EssentialApp project]
- need to create a workspace
- drag the EssentialFeed project (from finder with XCode close for that project) into the EssentialApp project (top) 
- response to create a new workspace (a workspace can combine multiple projects) EssentialFeed/EssentialApp.xcworkspace
- now there are the EssentialFeed project and the EssetialApp project
- in the EssetialApp project add the other two modules as embeded frameworks (+) EssentialFeed and EssentialFeediOS
- (main tab - Frameworks, Libraries and Embedded Content)
- now from the EssentialApp project we have access to the EssentialFeed components
[create EssetialApp workspace combining EssentialApp and EssentialFeed projects]
- in the scene delegate import both modules
- create a feedViewController with the FeedUIComposer
- create an imageLoader (use the RemoteFeedImageDataLoader)
- create a feedLoader (use the RemoteFeedLoader)
- create a client (use URLSessionHTTPClient)
- create a session (use URLSession configuration .ephemeral) (own caching strategy)
- create the url (use the one in the course) 
- access the window and set the rootViewController 
- run the app and it should work!
```

### 2) Composite Pattern: Implementing a Flexible & Composable Strategy for Loading Data with Fallback Logic
```
[remove not used test cases (also EssentialAppUITests target)]
[configure EssentialApp scheme to execute tests in random order and gather coverage for the EssentialApp targetq]
- create RemoteWithLocalFallbackFeedLoaderTests
T) test_load_deliversRemoteFeedOnRemoteSuccess
- assert that a 'receivedFeed' is equal to the stubbed result 'remoteFeed'
- call load in the sut (get a result back)
- create 'receivedFeed' of type of optional array of FeedImage
- capture in that variable the feed in the success case (can move the assertion there and remove the variable)
- otherwise (failure case) we fail the test ("Expected successful load feed result, got 'result' instead"
- add an expectation that is fullfilled when getting the result and wait for it after invoking load
- instanciate the sut (RemoteWithLocalFallbackFeedLoader with remote and local as parameters)
- create the actual RemoteWithLocalFallbackFeedLoader (with the init method) (import EssentialFeed)
- add the remoteLoader (RemoteFeedLoader) and localLoader (LocalFeedLoader) 
- but these need dependencies! 
- change the init with the abstractions themseves (FeedLoader, FeedLoader)
- create a LoaderStub (use it for remoteLoader and localLoader) make conform to FeedLoader
- we could create protocols RemoteFeedLoader and LocalFeedLoader inheriting from the FeedLoader
- to get the compiler help with the order of the parameters
- need to create a RemoteLoaderStub (RemoteFeedLoader) and a LocalLoaderStub (LocalFeedLoader)
- then anotate that the concrete types implements these protocols with extensions
- but we are going to follow the simplest solution:
- change parameters with primaryLoader and fallbackLoader (also change the instances)
- rename class to FeedLoaderWithFallbackComposite
- rename test class to FeedLoaderWithFallbackCompositeTests
- rename 'remoteFeed' to 'primaryFeed'
- rename test to test_load_deliversPrimaryFeedOnPrimaryLoaderSuccess
- make FeedLoaderWithFallbackComposite conform to FeedLoader
- create the 'primaryFeed' (uniqueFeed) and 'fallbackFeed' (uniqueFeed)
- stub these results into primaryLoader (LoaderStub(result: .success(primaryFeed)) and fallbackLoader 
- impplement the uniqueFeed function (like the previous one)
- add the result property to the stub (complete with this result when the load method is called) 
- add the 'primary' property to FeedLoaderWithFallbackComposite (set it in the init method)
[FeedLoaderWithFallbackComposite.load delivers primary feed on primary loader success]
- create the makeSUT (with primaryResult and fallbackResult as parameters) (track for memory leaks also)
- create the trackForMemoryLeaks helper
- use FeedLoader as return parameter!
[Extract system under test (SUT) creation into a factory method]
T) test_load_deliversFallbackFeedOnPrimaryFailure
- repeat the same strategy, create the anyNSError helper 
- add the 'fallback' property to the SUT 
- add the logic to load from fallback when primary fails to load (failure case)
[`FeedLoaderWithFallbackComposite.load` delivers fallback feed on primary loader failure]
- create 'expect sut toCompleteWith' helper
[extract duplicate load logic from test into a helper method]
T) test_load_deliversErrorOnBothPrimaryAndFallbackLoaderFailure
[`FeedLoaderWithFallbackComposite.load` delivers error on both primary and fallback failure]
- move FeedLoaderWithFallbackComposite to production (change access control)
- import the EssentialApp in the test
[move `FeedLoaderWithFallbackComposite` to production]
- create the FeedImageDataLoaderWithFallbackCompositeTests
T) test_init_doesNotLoadImageData
- create a primaryLoader and a fallbackLoader (using a LoaderSpy)
- create the FeedImageDataLoaderWithFallbackComposite use an internal Task class to return the task 
- assert that the primaryLoader.loadedUrls is empty upon init (also for the fallbackLoader)
- in the LoaderSpay (conforming to FeedImageDataLoader) also use an internal Task class
- store the messages sent to the spy (url and completion) and use a computed property for the loaded urls  
[`FeedImageDataLoaderWithFallbackComposite.init does not load image data]
T) test_loadImageData_loadsFromPrimaryLoaderFirst
- create the anyURL helper
[`FeedImageDataLoaderWithFallbackComposite.loadImageData` loads from primary loader first] 
[Extract system under test (SUT) creation into a factory method]
- create anyNSError helper
- add 'complete with error' function to LoaderSpy
[FeedImageDataLoaderWithFallbackComposite.loadImageData loads from fallback loader on primary loader failure]
T) test_cancelLoadImageData_cancelsPrimaryLoaderTask
- add a callback to the Task internal struct of LoaderSpy
- rename Task to TaskWrapper (store an optional FeedImageDataLoaderTask called wrapped) and execute the 
- cancel function of the wrapped when cancel received
[FeedImageDataLoaderWithFallbackComposite.loadImageData cancels primary loader task on cancel]
T) test_cancelLoadImageData_cancelsFallbackLoaderTaskAfterPrimaryLoaderFailure
[FeedImageDataLoaderWithFallbackComposite.loadImageData cancels fallback loader task on cancel after a primary loader failure]
T) test_loadImageData_deliversPrimaryDataOnPrimaryLoaderSuccess
- add 'complete with data' function to LoaderSpy
[`FeedImageDataLoaderWithFallbackComposite.loadImageData` delivers primary data on primary loader success]
T) test_loadImageData_deliversFallbackDataOnFallbackLoaderSuccess
[`FeedImageDataLoaderWithFallbackComposite.loadImageData` delivers fallback data on fallback loader success]
T) test_loadImageData_deliversErrorOnBothPrimaryAndFallbackLoaderFailure
[`FeedImageDataLoaderWithFallbackComposite.loadImageData` delivers error on both primary and fallback loader failure]
[move `FeedImageDataLoaderWithFallbackComposite` to production]
[extract memory leak tracking helper into a shared scope to remove duplication]
[Extract test helpers into a shared scope to remove duplication]
- create the remote and local feed loaders in the scene delegate and compose them (to test)
- setup CI pipeline 
- go to scheme selection -> Manage schemes 
- migrate the Ci_iOS to the workspace (select the workspace as the container of the CI_iOS scheme)
- in the test configuration (left Tab) -> add the essentialAppTests target (randomize the execution order)
- in 'Options' tab include the EssentialApp target for gathering coverage
- update ci configuration file (travis)
```

### 3) Interception: An Effective, Modular and Composable Way of Injecting Behavior and Side-effects in the App Composition
```
- to store the feed locally when it is fetch from the remote source, one solution would be to make 
- the FeedLoaderWithFallbackComposite perform that (changing to the concrete LocalFeedLoader type)
- but that solution is not flexible 
- add FeedLoaderCacheDecoratorTests
T) test_load_deliversFeedOnLoaderSuccess
- expect that the sut completes with a feed (success) (using 'expect sut toCompleteWith')
- when the decoratee 'loader' success with that feed
- use a LoaderStub for the the loader with the stubbed result: '.success(feed)'
- use same helper from previous lecture (also the uniqueFeed) 
- create the FeedLoaderCacheDecorator
T) test_load_deliversErrorOnLoaderFailure
- repeate the same logic but subbing a .failure case with an error (anyNSError)
[`FeedLoaderCacheDecorator.load` delivers decoratee loader result (either success or failure)]
- move FeedLoaderStub (own file)
[Extract `FeedLoaderStub` into a shared scope to remove duplication]
- move uniqueFeed (Shared test helpers)
[Extract `uniqueFeed` factory helper into a shared scope to remove duplication]
- move the 'expect' helper (XCTestCase+FeedLoader)
- to make the function 'expect' only accessible for the test that care about that we can 
- use a subclass of the XCtest class and then use that class in the tests
- but class inheritance is not composable (one class can only inherit from other)
- we can use a protocol FeedLoaderTestCase constrained to XCTestCase ('inherits' from) 
- and add an extension of that protocol and the class conforming to that protocol will have access to
- this way we can conform to different protocols in the tests (oposed to the class aproach when 
- you can only inherit from one class only)
[Extract `FeedLoader` test helpers into a shared protocol extension to remove duplication]
- create the makeSUT (with loaderResult)
[Extract system under test (SUT) creation into a factory method]
T) test_load_cachesLoadedFeedOnLoaderSuccess
- assert that the messages of the 'cache' are equal to [.save(feed)] 
- create a CacheSpy to store the messages (Message enum type)
- add the 'cache' parameter to the FeedLoaderCacheDecorator init 
- instead of using the concrete type LocalFeedLoader we can create an abstraction (protocol)
- FeedCache (FeedSaver other option) that has the method save with the related Result type
- make the CacheSpy conform to that protocol
- change makeSUT to accept a cache (CacheSpy type) with a default value (to not brake the older tests)
- change production code to invoke the save method in the cache when getting a cache result otherwise
- with an empty cache (only for testing) (need to add the 'cache' property in the class)
[`FeedLoaderCacheDecorator.load caches loaded feed on loader success]
T) test_load_doesNotCacheOnLoaderFailure
- use an if let (only when having a cache then save it)
[`FeedLoaderCacheDecorator.load` does not cache feed on loader failure]
- refactor to use the 'map' statement
[replace if-try-statement with map] 
- move FeedCache (Feed Feature group) (make it public)
[move `FeedCache` to the `Feed Feature` production group]
- make the LocalFeedLoader implement the FeedCache protocol (change SaveResul to FeedCache.Result)
[make the `LocalFeedLoader` implement the FeedCache protocol (so it can be composed)]
- move the FeedLoaderCacheDecorator (above the FeedImageData..Composite)
[move `FeedLoaderCacheDecorator` to production]
- create an extension of the FeedCache that have a saveIgnoringResult func 
[create saveIgnoringResult method to clarify intent]
- create FeedImageDataLoaderCacheDecoratorTests
- repeat similar steps as the previous tests
[`FeedImageDataLoaderCacheDecorator.loadImageData` delivers decoratee result (either success or failure)]
[extract `FeedImageDataLoaderSpy` into a shared scope to remove duplication]
[extract `FeedImageDataLoader` test helpers into a shared protocol extension to remove duplication]
[`FeedImageDataLoaderCacheDecorator.loadImageData` caches loaded data on loader success]
[`FeedImageDataLoaderCacheDecorator.loadImageData` does not cache image data on loader failure]
[move `FeedImageDataCache` to the `Feed Feature` production group]
[make the `LocalFeedImageDataLoader` implement the `FeedImageDataCache` protocol (so it can be composed)]
[move `FeedImageDataLoaderCacheDecorator to production]
[create `saveIgnoringResult` method to clarify intent]
```

### 4) Validating Acceptance Criteria with High-Level UI Tests, Controlling Network and App State in UI tests with Launch Arguments and Conditional Compilation Directives
```
- create a new tests target (+ from EssentialApp) (ios - UI testing Bundle) EssentialAppUIAcceptanceTests
- check the target application is correct (EssentialApp)
- configure the EssentialApp scheme (remove the UI Tests)
- add a new scheme (manage schemes -> +) Target: EssentialAppUIAcceptanceTests name: (idem)
- container: EssentialApp Workspace
- configure the CI_iOS scheme - in the test tab add the EssentialAppUIAcceptanceTests (randomize order)
[add UI Test target for running high-level Acceptance Tests]
T) test_onLaunch_displaysRemoteFeedWhenCustomerHasConnectivity
- the json file provides 22 images so the idea is to check the count of the cells 
- assert that the app.cells.counts is 22
- when the app.launch
- given (create the app using XCUIApplication)
- you cannot check the images that are on the cells that are off screen
- so check that the app.cells.firstMatch.images.count is 1
- run the test it should fail 
- in the scene delegate add controller with there dependencies (remoteFeedLoader and remoteImageLoader)
- add the other dependencies (remoteClient and remoteURL) TS
[displays remote feed on launch when customer has connectivity]
- add an identifier to count the cells that we want to count ("feed-image-cell") .matching(identifier:)
- repeate the same but with the firsImage firstMatch ("feed-image-view") (assert that it exists) TF
- add the identifiess (in storyboard) TS
[improve coverage by using identifiers for finding feed image cells]
T) test_onLaunch_displaysCachedRemoteFeedWhenCustomerHasNoConnectivity
- launch the app (onlineApp) then launch the app again without connetivity (passing launch arguments) 
- offlineApp.launchArguments = ["-connectivity", "offline"]
- then check that we should have the same amount of cells and at least an image 
- in the scene delegate create a function makeRemoteClient and based on the argument return the normal 
- client or the AlwaysFailingHTTPClient (use the UserDefaults.standard.string(forKey:) function)
- create the AlwaysFailingHTTPClient TF
- in scene delegate add the localStoreURL, localStore, localFeedLoader, and localImageLoader
- compose the loaders as before (with the primary and fallbacks) TS
[displays cached feed on launch when customer has no connectivity]
T) test_onLaunch_displaysEmptyFeedWhenCustomerHasNoConnectivityAndNoCache
- launch the app and assert that feedCells count is 0 
- add another lanch argument (-reset)
- add a check in the scene delegate (using CommandLine.arguments.contains("-reset")
- and delet the local store (using the FileManager.default.removeItem(at: localStoreURL))
[displays empty feed when customer has no connectivity and no cache]
- reset the state also in the previous test (before loading the online app)
- also in the first test 
[reset cache in every test run to make sure tests run in a clean state and dont influence the result of other tests.]
- add compilation directives to prevent the test code to be deployed in production (#if DEBUG #endif)
- refactor the makeRemoteClient to use an if statement and wrapped with #if statments 
- wrap the AlwaysFailingHTTPClient with #if statements
[add #if DEBUG compilation directive to prevent test-specific code from being deployed in production]
- create a new class (own file) DebuggingSceneDelegate (subclass of SceneDelegate)
- override the funtionality of the scene willConnectTo .. function
- keep only the debug code and then forward the message to the super class 
- override also the makeRemoteClient and if the connectivity flag is offline return the always failing 
- otherwise return the super.makeRemoteClient 
- change the functions of the super class to be internal (no modifiers - default)
- expose the local storeURL (to use it from the subclass)
- wrap the hole new class with the compilation directives 
- tell the app to use the new version of scene delegate in the app delegate:
- implement the function 'application configurationForConnecting options' and set in the returned 'configuration'
- the debug version of the scene delegate (delegateClass property) when in DEBUG (#if DEBUG #endif) 
- (othewise it uses the one set in the info.plist - the standard SceneDelegate)
[move DEBUG code paths from the main SceneDelegate to a new DebuggingSceneDelegate subclass to separate debug- and test-specific code from production code]
- to not need to relay in the server to run the tests
- add a new option "online" to the -connentivity flag 
- rename the AlwaysFailingHTTPClient to DebuggingHTTPClient (add an init paramenter 'connectivity')
- depending on the connectivity paramenter return the successfull response or failure
- create the makeSuccessfulResponse returning the Data and the HTTPURLResponse 
- create also makeData(for:url), makeImageData and makeFeedData
[intercept HTTP requests with canned responses during UI tests to eliminate network flakiness - We can now run UI tests without internet connection.]
```

### 5) Validating Acceptance Criteria with Fast Integration Tests, Composition Root, and Simulating App Launch & State Transitions
```
- create SceneDelegateTests (EssentialAppTests)
T) test_sceneWillConnectToSession_configuresRootViewController
- asert that the rootviewController of the sut window is a UINavigationController (XCTAssertTrue is)
- create the sut (SceneDelegate) import the EssentialApp as @testable
- call the 'scence willConnectTo options' (but we can't provide the dependencies), so instead:
- move all the logic from the original 'willConnect' function to a configureWindow function to be able to call that 
- from the test
- configure a window to the sut (before calling configureWindow) TF
- embed the feed UI in a navigation controller TS
- assert that the rootNavigation is not nil (use 'root' as intermediate step then cast 'root' to UINavigationController)
- assert that the topController (topViewController) is a FeedViewController. import the EssentialFeediOS TS
[configures feed navigation as window root view controller]
- move the composition details (Composers group) from EssentialFeed target to the EssentialApp target (composition root)
- after DebuggingSceneDelegate file (remove old references after moving them) 
- also move the tests helpers (from helpers folder to helpers folder)
- and the FeedUIIntegrationTests (after SceneDelegateTest) 
- fix access control and imports (make public the FeedViewControllerDelegate (change the FeedViewController delegate 
- to be public, move it down), FeedImageCellControllerDelegate, make the tableModel private and a public setter 
- accessor function 'display(_ cellControllers: [FeedImageCellController])
- import the EssantialApp in the FeedUIIntegrationTests
[move Feed UI composition details from the EssentialFeediOS to the EssentialApp module (Composition Root)]
- create FeedAcceptanceTests (copy the tests from the EssentialAppUIAcceptanceTests)  @testable import EssentialApp
- create the sut (SceneDelegate) set the windows (UIWindow) get the 'nav' (window.rootViewController)
- finally get the 'feed' (nav.topViewController), use the helpers for the integration tests numberOfRenderdImageViews
- simulateFeedImageViewVisible(at: 0).renderedImage etc.. (import EssentialFeediOS and EssentialFeed)
- in order to be able to stub the results of the dependencies it is good to be received by the scene delegate 
- create the InMemoryStore and HTTPClientStub 
- copy the helper methods used in the DebugginSceneDelegate (makeImageData can use now the UIImage 
- extension make(withColor:)
- create the convenience initializer of the SceneDelegate (call self.init first) receiving the httpClient (HTTPClient)
- and the store (FeedStore & FeedImageDataStore)
- create lazy properties to store these 
- move the creation of the httpClient and the store to the lazy creation functions
- in makeRemoteClient return the lazy var 'httpClient'
- change the rendered image
- create renderedFeedImageData(at index)
- create 'launch' helper
[displays remote feed on launch when customer has connectivity]
[displays cached feed on launch when customer has no connectivity]
[displays empty feed on launch when customer has no connectivity and no cache]
- try to make the test fail (changing the composition) and it does but with an exception
- fix the index out of range issue returning nil in that case
[check number of cells before fetching cell at index to avoid out of bounds exception]
- delete the EssentialAppUIAcceptanceTest target (from file structure also), the scheme and remove it from the CI scheme
[remove EssentialAppUIAcceptanceTests in favor of faster and more precise integration tests]
- remove the DebuggingSceneDelegate
- remove code from 'application connectingscene .. '
- remove the makeRemoteClient, remove the localStoreURL
[remove unused debugging code that was previously used during UI tests]
T) test_onEnteringBackground_deletesExpiredFeedCache
- create a store (InMemoryFeedStore.withExpiredCahce)
- simulate enter background (enterBackground)
- assert that the store.feedCache is nil
T) test_onEnteringBackground_keepsNonExpiredFeedCache
- similar but assert that it should be not nil
- add the enterBackground helper 
- add the withExpiredFeedCache, withNonExpiredFeedCache helpers
- add the init
- add the sceneWillResignActive to the scene delegate TF
- make localFeedLoader be a lazy var so it can be reference from the function 
[validate feed cache on entering background]
[move HTTPClientStub to a shared scope in a separate file]
[move InMemoryFeedStore to a shared scope in a separate file]
```

### 6) Validating the UI with Snapshot Tests + Dark Mode Support

```
- create FeedSnapshotTests
T) test_emptyFeed
- create a sut (FeedViewController)
- call sut.display(emptyFeed())
- call sut.snapshot()
- create makeSUT (instanciate FeedViewController from storyboard, call loadViewIfNeeded)
- create 'emptyFeed' func
- create 'snapshot' func extension in UIVieController
- return the rendered image by rendering the view in the action context
- capture the snapshot with a constant and add a breakpoint to see the snapshot  
- create record function (receives the snapshot and a name)
- convert to png then create the path 'snapshotURL' (use the #file path)
- create the directory then write the data to the url
[record empty feed snapshot]
T) test_feedWithContent
- repeat the same but with feedWithContent() instead of emptyFeed()
- create ImageStub implementing the FeedImageCellControllerDelegate
- when the method didRequestImage is invoked we need to the tell the controller to 'display' a stubbed viewModel
- need a reference to the controller (FeedImageCellController) (weak)
- create a reference to the viewMode (FeedImageViewMode<UIImage>)
- add an initializer with takes a description, location and image
- as the FeedImageViewModel doen't have a public initializer need to @testable import EssentialFeed
- create the feedWithContent helper 
- add the make(withColor:) helper: in new Helpers folder (copy from the EssentialApp module)
- add a private extension to the FeedViewController to map the stubbed images to FeedImageCellControllers 
- and call 'display' with this array of FeedImageCellControllers
[record feed with content snapshot]
T) test_feedWithErrorMessage
- test with multiple lines -> not looking good
- fix the issue 
- create UITableView+HeaderSizing (with sizeTableHeaderToFit func)
- update the FeedViewController in viewDidLayoutSubviews call the sizeTableHeaderToFit on tableView
- fix issue in storyboard (not all constraints)
[fix table header resizing for multi-line label]
[record feed with error message snapshot]
T) test_feedWithFailedImageLoading
- create feedWithFailedImageLoading func (stubbed images with nil images)
[record feed with failed image loading snapshot] 
- create the assert func (store the snapshot in a temporary folder, add the link to that in the error message)
[assert snapshots match the stored snapshots]
- add the SnapshotConfiguration (with size, safeAreaInsets, layoutMargins and traitCollection
- to override the configuration we use a custom window SnapshotWindow
- fix dark mode support in storyboard (commit this part first)
- table view background default 
- description and location secondary label color 
- image container secondary system background color
- retry button system background color
[add dark mode support]
[assert snapshots for light and dark mode using an iPhone8 configuration]
[move UIViewController snapshot helpers to separate file]
[move `XCTestCase` snapshot helpers to separate file]
```

### 7) Preventing a Crash when Invalidating Work Based on UITableViewDelegate events
```
- fix issue when the system call didEndDisplaying (when reload data is called)
- UIKit will call didEndDisplaying also when reloadData is called
T) test_loadFeedCompletion_rendersSuccessfullyLoadedEmptyFeedAfterNonEmptyFeed
- for persformance reason UIKit does not reload the table immediately after reloadData is called
- in 'assertThat' func add tableView.layoutIfNeeded and RunLoop.main.run(unitl: Date()) -> Test crash
- fix it adding a guard to check the tableModel count with the indexPath.row
- but this doesnt solve the problem (will cancel the new image cell controllers) 
- so create private var loadingControllers dictionary with keys IndexPath
- every time we receive a new model we reset it (display func)
- and cancel will cancel that loadingController at that indexPath if any then set it to nil
- set the reference in the 'cellController forRowAt' func
[fix potential bug when cancelling requests in UITableView didEndDisplayingCell method - This method is invoked after calling `reloadData`, so we'd be cancelling requests in the wrong models or crash in case the model has less items than the previous model]
[extract layout cycle steps into a shared helper extension]
```

### 8) Organizing Modular Codebases with Horizontal and Vertical Slicing
```
- create a framework (macOS) EssentialFeedAPI (add support for the iphonesimulator, iphoneos
- add the EssentialFeed framework as frameworks and libraries
- drag the files to the new EssentialFeedAPI folder
- select all and update the target membership
- drag test files and update the target memership as well
- now we gain a new scheme also, try to run the test 
- fix import statmanets 
- try to run the application now
- add the EssentiaFeedAPI to the frameworks and libraries
- fix the import statments
- repeat the steps with each module 
```

### 9) Continuous Delivery and Deployment: Automating the App Deploy to App Store Connect
```
Tidy up for v1.0 release PR:
- add an icon to the assets catalog
[add app icon]
- change the lauch screen to be as similar as possible to the first screen (feed inmbeded in a nav controller)
- embed the launch screen in a navigation controller
[embed launch screen into a navigation controller for a smoother initial app transition]
- remove the Main storyboard (deleting the file is not enough) 
- select the app project -> EssentialApp target -> General -> Custom iOS Target properties ->
- Main storyboard file base name (delete this row)
- Application Scene Manifest -> ... -> Storyboard Name: Main (delete this row)
- remove it from the info.plist -> Application Scene Manifest -> Scene Configuration -> Application Session Role
- Item 0 -> Storyboard Name (remove the row from the configuration) 
- the app now runs but it is all black (the window is not created automatically anymore)
- in the sceneDelegate `scene willConnectTo` create a window with the windowScene (scene receive by the func)
- it still don't work because the window is not key and not visible 
- in SceneDelegateTests 
T) test_configureWindow_setsWindowAsKeyAndVisible
- create a window 
- create the sut (sceneDelegate) 
- set the sut window to be the created window 
- call configureWindow on sut
- expect the created window to be the key window (assert true isKeyWindow)
- expect it is not hidden (assert false isHidden) TF
- after setting the window in the configureWindow call makeKeyAndVisible
[remove unnecessary Main storyboard - the initial set up happens in code]
[improve a test name]
- ready to deploy the application to the App Store Connect
- go to the App Store Connect web site, create a new application: iOS (Platform), Essential App (Name),
- English (U.S.) (Primary Language), XC ...com.essential.EssentialAppCaseStudy (Bundle ID)
- EssentialAppCaseStudy (SKU), Full access (User Access) -> Create
- fill the information like subtitle, privacy policy, category etc
- go to the test flight (set the test information message) -> Save
- change the bundle identifier in Xcode to match the bundle identifier in App Store Connect
[update bundle id to match app store connect]
- select the generic iOS device (in the scheme)
- Product -> Archive (now we have an archive we can distribute to the App Store)
- select the archive and press Distribute App -> App Store Connect -> Upload
- Automatically manage signing, check the profile, the team -> Upload
- App "EssentialApp" successfully uploaded
- go to the web and Provide Export Compliance Information -> No (no encryption) -> Start Internal Testing
- set the automatic delivery with github actions:
- go the github site .github folder -> deploy > ExportOptions.plist, certificate.p12.gpd and 
- profile.mobileprovition.gpg (encrypted with GPG)
- go to .github -> workflow CI-iOS.yml, CI-macOS.yml, Deploy.yml
- set the steps in the deploy file 
```

### 10) From Design Patterns to Universal Abstractions Using the Combine Framework
```
- in scene delegate import Combine
- create function makeRemoteFeedLoaderWithLocalFallback that returns a Combine publisher AnyPublisher that produces <[FeedImage], Error>
- copy and paste the existing code for creating the remoteFeedLoader
- lift the feed loader to the combine world (wrap the feed loader in a combine publisher) 
- return a Future and call remoteFeedLoader.load inside
- compiler complains about the return type, so we can change the return type to be a Future but
- it will tide up too much to the implementation 
- add .eraseToAnyPublisher to hide ithe implementation detail (Future)
- the Future block (attemptToFulfill) will be executed immediately upon creation (this is not what we want)
- one solution would be to wrap it with a Deferred publisher (its parameter is a createPublisher closure)
- since the type completions func signature match, we can pass the function remoteFeedLoader.load directly
- extract the code into an extension of RemoteFeedLoader:
- func loadPublisher that returns a AnyPublisher<[FeedImage], Swift.Error> (with the code created before)
- create a typealias Publisher of type AnyPublisher<[FeedImage], Swift.Error>
- use it also in the makeRemoteFeedLoaderWithLocalFallback as RemoteFeedLoader.Publisher
- in FeedLoaderCacheDecorator:
- import Combine and create an extension on Publisher where Output == [FeedImage] {}
- func caching(to cache: FeedCache) that returns a AnyPublisher<Output, Failure>
- copy and paste the map operation and add .eraseToAnyPublisher 
- (you can always replace a decorator with a map using publishers)
extension Publisher where Output == [FeedImage] {
    func caching(to cache: FeedCache) -> AnyPublisher<Output, Failure> {
        map { feed in
            cache.saveIgnoringResult(feed)
            return feed
        }.eraseToAnyPublisher()
    }
}
- since we are not altering the mapped values we can replace with 'handleEvents' which receives 
- the receiveOutput parameter: { feed in cache.saveIgnoringResult(feed) }
- (it is used especific to inject side effects)
extension Publisher where Output == [FeedImage] {
    func caching(to cache: FeedCache) -> AnyPublisher<Output, Failure> {
        handleEvents(receiveOutput: { feed in cache.saveIgnoringResult(feed) })
        .eraseToAnyPublisher()
    }
}
- since the signature is the same we can pass the function directly 
extension Publisher where Output == [FeedImage] {
    func caching(to cache: FeedCache) -> AnyPublisher<Output, Failure> {
        handleEvents(receiveOutput: cache.saveIgnoringResult)
        .eraseToAnyPublisher()
    }
}
- move the extension to the scene delegate file 
- add it to the chain 'return remoteFeedLoader.loadPublisher().caching(to: localFeedLoader)'
- in FeedLoaderWithFallbackComposite:
- import Combine and create an extension on Publisher
- func fallback(to fallbackPublisher: Publisher) -> Publisher (can't be done because we need asociated types)
- so func fallback(to fallbackPublisher: AnyPublisher<Output, Failure>) -> AnyPublisher<Output, Failure>
- we can use the 'catch' function (listen to errors and if there is any we want to replace the chain with the
- fallback) (catch receives a function that receives an error and returns a publisher)
- self.catch(fallbackPublisher) (change the fallbackPublisher to be a function that receives an error and return 
- an AnyPublisher (@escaping), then as always .eraseToAnyPublisher() 
- as we ignore the error in the composite we can ignore it also in the publisher
- so func fallback(to fallbackPublisher: @escaping () -> AnyPublisher<Output, Failure>) -> AnyPublisher<Output, Failure> {
- self.catch { _ in fallbackPublisher() }.eraseToAnyPublisher
- (catch operator on the Publisher is equivalent to the created Composite)
- (a way of injecting fallback logic into publishers)
- move the extension to the scene delegate file
- add it to the chain ....caching(to: localFeedLoader).fallback(to: localFeedLoader.loadPublisher)
- in order to do that we first need to 
- change the extension on RemoteFeedLoader to be on FeedLoader instead (remove the swift. from the error)
- in FeedUIComposer:
- change the feedComposedWith function feedLoader parameter to a parameter function that receives nothing and returns 
- a FeedLoader.Publisher  
- FeedLoader (but we need one more operation to do that -> migrate the MainQueueDispatchDecorator)
- in MainDispatchDecorator:
- import Combine and create an extension on Publisher
- func dispatchOnMainQueue() -> AnyPublisher<Output, Failure> (does not change the types only injects dispatch decorator)
- use receive(on: Scheduler), so receive(on: DispatchQueue.main)
- as always add the .eraseToAnyPublisher
- doing like this will always dispatch ayncronosly to the main queue (will not check if already in the main thread)
extension DispathQueue {
    static var immediateWhenOnMainQueueScheduler: ImmediateWhenOnMainQueueScheduler{ 
        ImmediateWhenOnMainQueueScheduler()
    }

    struct ImmediateWhenOnMainQueueScheduler: Scheduler {
        typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType
        typealias SchedulerOptions = DispatchQueue.SchedulerOptions
        
        var now: SchedulerTimeType { DispathQueue.main.now }
        
        var minimumTolerance: SchedulerTimeType.Stride { DispatchQueue.main.minimumTolerance }
        
        func schedule(after date: SchedulerTimeType, tolerance: SchedulerTimeType.Stride, options: SchedulerOptions?, 
        _ action: @escaping () -> Void) { 
            guard Thread.isMainThread else {
                return DispatchQueue.main.schedule(options: options, action)
            }
            action()
        }
        
        func schedule(after date: SchedulerType ..) {
            DispatchQueue.main.schedule(after: date, tolerance: tolerance, options: options, action)
        }
        
        func schedule(after date: .. interval ..) {
            DispatchQueue.main.schedule(after: date, interval: interval, tolerance: tolerance, options: options, action)
        }
    }
}
- receive(on: DispatchQueue.immediateWhenOnMainQueueScheduler).eraseToAnyPublisher()
- move these extensions to the scene delegate
- now in FeedUIComposer instead of using the decorator 
- { feedLoader().dispatchOnMainQueue }
- in FeedLoaderPresentationAdapter:
- change to recieve also a function that returns a FeedLoader.Publisher
private var cancellable: Cancellable? 
(to hold the result of the subsciption otherwise it is deallocated, and when deallocated it is cancelled) 
..
cacellable = feedLoader().sink(
    receivedCompletion: { [weak self] completion in 
        switch completion {
        case .finished: break
        case let .failure(error):
            self?.presenter?.didFinishLoadingFeed(with: error)
        }
    }, receivedValue: { [weak self] feed in
        self?.presenter?.didFinishLoadingFeed(with: feed)
    }
}
- In scene delegate:
- complete the composition chain 
- feedLoader: makeRemoteFeedLoaderWithLocalFallback
- import Combine
- run the tests, got a build error. inject the loader.loadPublisher TS
- delete the FeedLoaderWithFallbackComposite, FeedLoaderCacheDecorator, MainQueueDispatchDecorator extension for 
- FeedLoader 
- delete FeedLoaderCacheDecoratorTests, FeedLoaderWithFallbackCompositeTests 
[replace FeedLoader composition with Combine operators]
- repeat the same with the FeedImageDataLoader
- replace the imageLoader parameter in FeedViewAdapter to be a function that accepts a url an return a publisher
- delete FeedImageDataLoaderWithFallbackComposite, FeedImageDataLoaderCacheDecorator, MainQueueDispatchDecorator
- delete FeedImageDataLoaderWithFallbackCompositeTests, FeedImageDataLoaderCacheDecoratorTests
[replace FeedImageDataLoader composition with Combine operators]
- move combine helpers to CombineHelpers folder
- 
[move Combine helpers to a new file]
[move dispatchOnMainQueue operator to the point of use (before subscription with `sink`)]
```

```
- the main thread can run queues that are not the Main Queue and some frameworks need to dispatch the
- work to the main queue (main queue always runs in the main thread by the way) 
- because of that it is not enough to check isMainThread 
- to achieve this we can use an private isMainQueue function 
- using the setSpecific(key: value:) 
- and then with getSpecific(key) if it matched the value then we are in the same queue  
private static let key = DispatchSpecificKey<UInt8> 
private static let value = UInt8.max

init() {
    DispatchQueue.main.setSpecific(key: Self.key, value: Self.value)
}

private func isMainThread() -> Bool {
    DispatchQueue.getSpecific(key: Self.key) == Self.value
}

- to prevent multiple instanciation of this class we can use a singlenton
static let shared = Self()
private init.. 
[check isMainQueue instead of just isMainThread since there's no guarantee that the main thread is running the main queue]
```

## FIFTH MODULE - ADDING A NEW FEATURE

### 1) [Image Comments API] From Dependency Injection to Dependency Rejection
```
- create new LoadImageCommentsFromRemoteUseCaseTests based on LoadFeedFromRemoteUseCaseTests
- copy and paste the tests TS
- find and replace RemoteFeedLoader -> RemoteImageCommentsLoader BE
- create RemoteImageCommentsLoader based on RemoteFeedLoader (copy, paste and rename class) TF
- create ImageCommentsMapper based on FeedItemsMapper (copy, paste and rename)
- change to RemoteImageCommentsLoader.Error TS
[duplicate RemoteFeedLoader as RemoteImageCommentsLoader]
- the specs says that it is ok when receiving 2xx responses
- test_load_deliversErrorOnNon2xxHTTPResponse [199, 150, 300, 400, 500] TS
- test_load_deliversErrorOn2xxHTTPResponseWithInvalidJSON [200, 201, 250, 280, 299] TS
- test_load_deliversNoItemsOn2xxHTTPResponseWithEmptyJSONList [200, 201, 250, 280, 299] TF
- create static func isOK(_ response: HTTPURLResponse) -> Bool in ImageCommentsMapper
- (200...299).contains(reponse.statusCode) TS
- test_load_deliversItemsOn2xxHTTPResponseWithJSONItems [200, 201, 250, 280, 299]
[delivers proper results on 2xx response]
- change makeItem id: UUID, message: String, createdAt: Date, username: String
- use not yet created ImmageComment, update id, message, created_at, author: ["username": username] 
- ISO8601DateFormatter().string(from: createdAt) -> this depend from the time zone and locale
- createdAt: (date: Date, iso8601String: String)
- remove the compact map
- create ImageComment (Image Comments Feature folder) public struct (public init)
- make it Equatable 
- fix test setup message: "a message", createdAt: (Date(timeIntervalSince1970: 1598627222),
- "2020-08-28T15:07:02+00:00"), username: "a user name"
- 1577881882 "2020-01-01T12:31:22+00:00" BE
- in RemoteImageCommentsLoader:
- public typealias Result = Swift.Result<[ImageComment], Swift.Error> remove FeedLoader conformance
- move the mapping to the mapper 
- private struct Item: Decodable { let id ... }
- private stuct Author: Decodable { let username: String}
- var comments: [ImageComment] { items.map{ ImageComment(id: $0.id ... }}
- let decoder = JSONDecoder()
- decoder.dateDecodingStrategy = .iso8601 TS
[add image comment data model]
[implement ImageComment mapping]
- the idea is to have different modules for the client implementation and client interface
- in Essential Feed:
- create Shared API folder (move the HTTPClient) - interface
- create Shared API Infra folder (move URLSessionHTTPClient) - implementation
- in EssentialFeedTests:
- create Shared API folder (below Helpers)
-- Helpers (HTTPClientSpy) 
- create Shared API Infra folder
-- Helpers (URLProtocolStub)
- URLSessionHTTPClientTests
[move HTTPClient protocol and implementation to standalone folders representing modules]
- in EssentialFeed:
- create Image Comment API folder (RemoteImageCommentsLoader, ImageCommentsMapper)
- in EssentialFeedTests: 
- create Image Commets API folder (LoadImageCommentsFromRemoteUseCaseTests) TS
[move Image Comments API to standalone folders representing modules]
- both remotes are almost identical so to make them even more identical
- refactor old FeedItemsMapper (move the RemoteFeedItem to the Root)
- use a helper var images: [FeedImage] { items.map { FeedImage(id: $0.id ...}}
- move the RemoteFeedItem inside the Root delete empty file (RemoteFeedItem)
[move FeedImage mapping to the FeedItemsMapper]
- in EssentialFeedTests/Shared API create RemoteLoaderTests
- copy and paste the tests from LoadFeedFromRemoteUseCaseTests
- rename RemoteFeedLoader to RemoteLoader BE
- add RemoteLoader to EssentialFeed/Shared API (copy and paste from RemoteFeedLoader) TF
- change the error in the mapper to Error.invalidData TS
[duplicate RemoteFeedLoader as RemoteLoader]
- rename test_load_deliversErrorOn200HTTPResponseWithInvalidJSON to 
- test_load_deliversErrorOnMapperError
- rename test_load_deliversItemsOn200HTTPREsponseWithJSONItems to 
- test_load_deliversMappedResource
- remove case specific tests test_load_deliversErrorOn200 ...
- the idea is to inject the mapper (to the sut in this case) makeSUT(mappper: {_, _ in 
    throw anyError
})
- the mapper receives the data and the response and returns the source
- change invalidJSON to anyData (any data pass to a mapper that throws an error should deliver 
- .invalidData
- change the makeSUT to inject the mapper: @escaping Mapper
- typealias Mapper<Resource> = (Data, HTTPURLResponse) throws -> Resource
- pass the mapper to the remote loader implementation RemoteLoader(... mapper: mapper)
- move the Mapper to the RemoteLoader and move the generic to the RemoteLoader type 
- keep a reference to the mapper (stored property, initialized in init)
- back in RemoteLoaderTests:
- change mapper: @escaping RemoteLoader<String>.Mapper (any type will do)
- find and replace RemoteLoader to RemoteLoader<String>
- add the mapper to the instance deallocation test {_, _ in "any"} and a default to the makeSUT
- in the test_load_deliversMappedResource 
- let resource = "a resource"
- data: Data(resource.utf8)
- .. mapper: { data, _ in String(data: data, encoding: .utf8)!
- change the RemoteLoader Result = Swift.Result<Resource, Switf.Error>
- remove FeedLoader conformance, use the mapper in the RemoteLoader 
- change the map function to be an instance function TS
[implement generic RemoteLoader]
- in the RemoteImageCommentsLoader:
- public typealias RemoteImageCommentsLoader = RemoteLoader<[ImageComment]>
- (using a typealias don't break clients)
public extension RemoteImageCommentsLoader {
    convenience init(url: URL, client: HTTPClient) {
        self.init(url: url, client: client, mapper: ImageCommentsMapper.map)
    }
} TS
- remove duplication in the tests (LoadImageCommentsFromRemoteUseCaseTests)
- leave test_load_deliversErrorOnNon2xxHTTPResponse, 
- test_load_deliversErrorOn200HTTPResponseWithInvalidJSON, 
- test_load_deliversNoItemsOn2xxHTTPResponseWithEmptyJSONList and
- test_load_deliversItemsOn2xxHTTPReponseWithJSONItems
[replace the RemoteImageCommentsLoader with RemoteLoader to remove duplication]
- repeate the same with the RemoteFeedLoader (also remove duplication from tests)
[replace RemoteFeedLoader with generic RemoteLoader to remove duplication]
- in the Feed API module the RemoteFeedLoader is composed with the RemoteLoader and the mapper
- run the tests in the EssentialApp scheme BE
- in the sceneDelegate:
- extension RemoteLoader: FeedLoader where Resource == [FeedImage] {}
[make RemoteLoader conform to FeedLoader in the composition root]
- the idea is to compose the remotes in the composition root
- so the idea is to make the mapper public so that can be use to compose the remote loaders
- the mappers can be test in isolation (only test the behavior of the mapper) 
- in LoadFeedFromRemoteUseCaseTests
- make FeedItemsMapper public (class and map method)
- change test_load_deliversErrorOnNon200HTTPResponse to test_map_throwsErrorOnNon200HTTPResponse 
change test to throws 
try samples.enum...
    let json = makeItemsJSON([])
    XCTAssertThrowsError(
        try FeedItemsMapper.map(json, from: HTTPURLResponse(anyURL(), statuCode: code,
            httpVersion:nil, headerField: nil)
    )
- remove the enumerated (index is not more needed)
- move json upwards, create a helper
private extension HTTPURLResponse {
    convenience init(statusCode: Int) {
        self.init(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)
    }
}
- test_map_throwsErrorOn200HTTPResponseWithInvalidJSON
- repeat the same procedure (statusCode: 200)
T) test_map_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() throws 
let result = try FeedItemsMapper...
XCTAssertEqual(result, [])
T) test_map_deliversItemsOn200HTTPResponseWithJSONItems() throws
let json = makeItemsJSON([item1.json, item2.json]
let result = ...
XCTAssertEqual(result, [item1.model, item2.model]
- remove all unneded test code
- rename test to FeedItemsMapperTests 
[test FeedItemsMapper in isolation]
- repate the same with the LoadImageCommentFromRemoteUseCaseTests (ImageCommentsMapperTests)
- make it public etc.. move the helpers to the SharedTestHelpers
[move tests helpers to shared scope]
[test ImageCommentsMapper in isolation]
- move ImageCommentsLoader (RemoteLoader extension) to the SceneDelegate BE
- in ImageCommentsMapper create a plublic enum Error: Swift.Error { case invalidData }
- now the ImageCommentsMapper is a standalone class TS
- more RemoteFeedLoader to the SceneDelegate BE
- repeate the same BE in the end to end tests
- replace the RemoteFeedLoader with a RemoteLoader and a mapper (FeedItemsMapper.map)
- delete RemoteImageCommentsLoader and RemoteFeedLoader files
- in SceneDelegate:
..lazy var remoteFeedLoader = RemoteLoader(url: remoteURL, client: httpClient, mapper: FeedItemsMapper.map
- remove RemoteImageCommentsLoader typealias and extension (it is not yet used)
[move RemoteLoader composition to the Composition Root]
- (do the same with the FeedImageDataLoader as an excercise)
- the generic RemoteLoader can be replaced using Combine 
- in the CombineHelpers: 
public extension HTTPClient
    typealias Publisher = AnyPublisher<(Data, HTTPURLResponse), Error>
    
    func getPublisher(url: URL) -> Publisher {
        var task: HTTPClientTask?
        
        return Deferred {
            Future { completion in
                task = self.get(from: url, completion: completion)
            }
        }
        .handleEvents(receiveCancel: { task?.cancel() })
        .eraseToAnyPublisher()
    }
}
- in the SceneDelegate:
- delete lazy var remoteFeedLoader = ..
- and just
return httpClient
    .getPublisher(url: remoteURL)
    .tryMap(FeedItemsMapper.map)
    .caching(to: localFeedLoader)
    .fallback(to: localFeedLoader.loadPublisher
- run the tests in the EssentialApp scheme TS
[replace RemoteLoader composition with HTTPClient publisher composed with FeedItemsMapper]
- delete the generic RemoteLoader and the test RemoteLoaderTests
- run the test in the CI_iOS scheme api end to end test BE
- in the EssentialFeedAPIEndToEndTests:
private func getFeedResult...
    let client = ephemeralClient()
    
    client.get(from: feedTestServerURL) { result in 
        receivedResult = result.flatMap { (data, response) in
            do {
                return .success(try FeedItemsMapper.map(data, from: response))
            } catch {
                return .failure(error)
            }
        }
        exp.fullfill()
    }
- in SceneDelegate delete extension RemoteLoader: FeedLoader where Resource == [FeedImage] {} TS
[remove unused RemoteLoader]
- FeedLoader is only conformed by the LocalFeedLoader so it is no more longer needed
- commented BE, remove FeedLoader conformance to LocalFeedLoader
- replace text containing FeedLoader.Result with Swift.Result<[FeedIamge], Error> BE
- replace text containing FeedLoader.Publisher with AnyPublisher<[FeedImage], Error>
- change the public FeedLoader publisher extension to LocalFeedLoader BE
- remove XCTestCase+FeedLoader
- in the extension FeedUIIntegrationTests+LoaderSpy
import Combine
class LoaderSpy: FeedImageDataLoader {
...
    private var feedRequests = [PassthroughSubject<[FeedImage, Error]>]()
    
    func loadPublisher() -> AnyPublisher<[FeedImage], Error> { //replace old load function
        let publisher = PassthroughSubject<[FeedImage], Error>()
        feedRequests.append(publisher)
        return publisher.eraseToAnyPublisher()
    }
    ...
    func completeFeedLoading(with: feed: [FeedImage] = [], at index: Int = 0) {
        feedRequests[index].send(feed)
    }
    
    func completesFeedLoadingWithError(at index: Int = 0) {
        let error = NSError(domain: "an error", code:0)
        feedRequests[index].send(completion: .failure(error))
    }
} 
- delete FeedLoader file 
[remove FeedLoader protocol as we don't need it anymore - we are composing the types with universal abstractions provided by the Combine framework]
- rename LoadFeedImageDataFromRemoteUseCaseTests to FeedImageDataMapperTests
- create FeedImageDataMapper
- copy the same test idea from the other mappers
[test FeedImageDataMapper in isolation]
- delete RemoteFeedImageDataLoader and replace in SceneDelegat by the new httpClient publisher
- fix EssentialFeedEndToEndTests
[replace RemoteFeedImageDataLoader with HTTPClient publisher composed with FeedImageDataMapper]
- delete HTTPClientSpy
[remove unused test spy]
```

### 2) [Image Comments Presentation] Reusable Presentation Logic
```
- we can add a delay to the feed loader and image data loader to see the changing states 
httpClient
    .getPublisher(url: url)
    .delay(for: 2, scheduler: DispatchQueue.main)
...
- the idea is to have different modules not depending from each other
Feed Presentation module: 
(FeedPresenter mapping FeedImage into FeedViewModel)
(FeddImagePresenter mapping FeedImage into FeedImageViewModel)
Image Comments Presentation module:
(ImageCommentsPresenter mapping ImageComments into ImageCommentsViewModel)
- so the flow would be (using the FeedPresenter and FeedImagePresenter as examples)
- data in -> creates view models -> data out to the UI
- void -> creates view models -> sends to the UI (didStartLoadingFeed)
- [FeedImage] -> creates view models -> sends to the UI (didFinishLoadingFeed with feed)
- Error -> creates view models -> send to the UI (didFinishLoadingFeed with error)
- so the generic case would be:  
- Resource -> create ResourceViewModel -> sends to the UI 
- Data -> UIImage -> send to the UI (we can apply the generic case here also)
- the idea is to create a generic presenter: LoadResourcePresenter
- create EssentialFeedTests/Shared Presentation/LoadResourcePresenterTests (below Helpers folder)
- copy the tests from the FeedPresenterTests TS
- find and replace FeedPresenter -> LoadResourcePresenter (4) BE
- create EssentialFeed/Shared Presentation/LoadResourcePresenter (below Shared API Infra)
- copy and paste from FeedPresenter
[duplicate FeedPresenter as LoadResourcePresenter]
- search for what it is specific and delete it (tests and production code) i.e. title
[remove title from generic presenter since it's specific to each presenter]
T) test_didStartLoading_displayNoErrorMessagesAndStartsLoading
- didStartLoading (test and production)
[rename method]
the idea is to convert a "resouce" to "resource view model"
T) test_didFinishLoadingResource_displaysResourceAndStopsLoading
let (sut, view) = makeSUT(mapper: { resource in
    resource + " view model"
})
sut.didFinishLoading(with: "resource")
...
.display(resourceViewModel: "resource view model")
.dipslay(isLoading: false)
- add the mapper to the makeSUT (mapper: @escaping (String) -> String) = { _ in "any"}
- add the mapper to the LoadResourcePresenter (on top) typealias Mapper = (String) -> String 
- hold a reference to it (private let mapper: Mapper) and set in the init
- pass the resource directly 
- fix makeSUT BE
- change didFinishLoading to match the new types 
feedView.display(resource) BE cannot convert value type String to FeedViewModel
- add public protocol ResourceView {
    func display(_ viewModel: String)
}
- change the init and stored property for new resourceView BE
- modify spy case display(resourceViewModel: String) TF
- add the mapper in LoadResourcePresenter
[displays mapped resource on successful resource loading]
- add the generic type 
public protocol ResourceView {
    associatedtype ResourceViewModel
    func display(_ viewModel: ResourceViewModel)
}
LoadResourcePresenter<Resource, View: ResourceView>
    public typealias Mapper = (Resource) -> View.ResourceViewModel
...
private let resourceView: View
- fix the tests with the generic <String, ViewSpy>
- add typealias ResourceViewModel = String
- to avoid duplication add private typealias SUT = LoadResourcePresenter<String, ViewSpy>
- (above the makeSUT func)
[make LoadResourcePresenter generic over the Resource types]
T) test_didFinishLoadingWithError...
- rename method didFinishLoading(with error: Error) TS
- rename ...localized("GENERIC_CONNECTION_ERROR" (global find and replace)
[replace "FEED_VIEW_CONNECTION_ERROR" key with "GENERIC_CONNECTION_ERROR"]
- don't like the idea of the key be used in different modules also not define in the String Files 
- create a new Shared.strings file in hte Shared Presentation "module"
- move the generic connection error to the new file 
- fix LoadResourcePresenterTests tests with table "Shared"
- and update the LoadResourcePresenter:
- private var loadError: String (tableName "Shared", bundle: Self.self) 
- comment: "Error ... can't load the resource ..."
- in FeedPresenterTests:
- ... localized( ...key: String, table: String = "Feed"
- and pass the table in the error case 
- change FeedPresenter with "Shared" (this is only temporary to make the tests pass)
- add a new test SharedPresentation/SharedLocalizationTests 
- (copy and paste from FeedLoalizationTests) table Shared, 
- bundle LoadResourcePresenter<Any, DummyView>.self
- private class DummyView: ResourceView {  .. Any ... }
- add localization (right pane) for all languages TS 
- change scheme to EssentialApp TF
- in FeedUIImtegrationTest we can create a DSL 
T) test_loadFeedCompletion_rendersErrorMessageOnErrorUntilNextReload
... (sut.errorMessage, loadError)
- in FeedUIIntegrationTests+Localization: 
- var loadError: String {
    localized("GENERIC_CONNECTION_ERROR", table: "Shared")
..
    func localized(_ key: String, table: String = "Feed"
} TS
- but still is not a good idea because the tables and key can change
- in LoadResourcePresenter make loadError public static
- then the DSL for the test
var loadError: String{
    LoadResourcePresenter<Any, DummyView>.loadError (add again the DummyView)
}
- remove the localized helper method BE
- create a new DSL feedTitle
- back in FeedUIIntegrationTests+Localization
var feedTitle: String {
    FeedPresenter.title
}
- now the test don't depend on the keys anymore TS
- we already test the keys in the presentation layer
[move "GENERIC_CONNECTION_ERROR" localization key to new Shared.strings]
- now the SharedLocalizationTests and FeedLocalizationTests are very similar 
- method to refactor: select eveything that is similar -> refactor extract method
- helper name is assertLocalizedKeyAndValues(in ) move it to the helper section
- move all helpers methods into the EssentialFeedTests/Helpers/SharedLocalizationTestHelpers
- inject file and line to the assetLocalizedKey... (3 places)
- rename presentationBundle to bundle
- use new method in FeedLocalizationTests
[remove duplication in the localization tests]
- LoadResourcePresenter still depend on types that lives in the Feed Presentation module
- rename FeedLoadingView to ResourceLoadingView (in all the project)
- create Shared Presentation/ResourceLoadingView (cut and paste the old one) 
- rename and move also ResouceLoadingViewModel 
[rename and move ResourceLoadingView and ResouceLoadingViewModel to Shared module]
- repeate the same for ResourceErrorView and ResourceErrorViewModel (do it manually cause it failed)
[rename and move ResourceErrorView and ViewModel to Shared module]
- in FeedPresenterTests (now the goal is to implement the FeedPresenter using the generic one)
T) test_map_createsViewModels
- create a feed and pass it to the FeedPresenter map function 
- assert that the vieModel.feed is equal to the feed 
- add the map function to the FeedPresenter ([FeedImage] -> FeedViewModel) public static
- use it in the didFinishLoadingFeed func (just to test it more)
[add FeedPresenter map]
- now we have all we need to replace in the composition with the generic one
- in FeedUIComposer (EssentialApp scheme)
- replace the FeedPresenter with the LoadResourcePresenter
- FeedViewAdapter needs now to implement the ResourceView protocol
- FeedLoaderPresentationAdapter presenter in now a LoadResourcePresenter<[FeedImage],
- FeedViewAdapter>
- update methods names 
- add the mapper function (map func created previously) TS
- the associated type ResourceViewModel is infered to be FeedViewModel because the FeedViewAdapter
- conforms to the ReourceView and implements the method display with that type
[replace FeedPresenter with generic presenter]
- remove all logic that is no longer need from the FeedPresenter (only remains the title and map)
- remove from FeedPresenterTests uneded tests (localized title and map)
[remove unused FeedPresenter logic]
- in line the table = "Feed"
[inline param]
- now the goal is to repeat the same but with image data loading to do so we can 
- make the presentation adapter generic (take FeedLoaderPresentationAdapter as a model)
- so rename it to LoadResourcePresentatioAdapter
- this is the component that makes the actual call to the source and pass the info to the presenter
- LoadResourcePresentationAdapter<Resource, View: ResourceView>
- feedLoader -> loader (also in init) 
- feed -> resource (update all types)
- move the conformance of the FeedViewControllerDelegate to an extension
- in didRequestFeedRefresh call loadResource (new name) 
- (EsentialApp scheme) BE
- in FeedUIComposer:
- LoadResourcePresentationAdapter<[FeedImage], FeedViewAdapter> TS
[make Presentation Adapter generic so it can be reused]
- now the idea is to replace the FeedImagePresenter by the new generic one
- in the FeedImagePresenter:
- the FeedImageViewModel has the image view part but also the loading (so it need to be splitted)
- in FeedImagePrsenterTests:
T) test_map_createsViewModel()
- create an image (uniqueImage) and map it with a FeedImagePresenter.map
- XCTAssert(viewModel.description, image.description) also .location
- add the generics FeedImagePresenter<ViewSpy, AnyImage>
- create the map function public static map(_ image: FeedImage) -> FeedImageViewModel<Image> TS
[add FeedImagePresenter map]
- in FeedViewAdapter: 
- replace the old FeedImageDataLoaderPresentationAdapter with the generic one
- LoadResourcePresentatioAdapter<Data, FeedImageCellController>
- pass a custom closure that calls the imageLoader with the model.url
- (this is called partial application of functions)
LoadResourcePresentationAdapter<Data,  
WeakRefVirtualProxy<FeedImageCellController>>(loader: { [imageLoader] in
    imageLoader(model.url)
})
- we can pass the viewModel to the FeedImageCellController directly
- (things that don't change can be passed by construction injection, things that can be change
- by property injection or method injection)
let view = FeedImageCellController(
    viewModel: FeedImagePresenter.map(model),
    delegate: adapter)
- with this we can get rid of the custom FeedImageDataLoaderPresentationAdapter and use the generic
- change the FeedImageCellController to get the viewModel: FeedImageViewModel<UIImage>
- and hold a reference to it 
- move all the settings of location and descrition to the view(in) func (cell creation) 
- (EssentialFeed) TS 
- (EssentialApp scheme) BE
- change the WeakRefVirtualProxy extension for FeedImageView to ResourceView 
- T.ResourceViewMode == UIImage (UIImage) model: UIImage
- add ImageCellController conformance to the ResourceView protocol
public typealias ResourceViewModel = UIImage (on top)
...
add public func display(_ viewModel: UIImage) {
    cell?.feedImageView.setImageAnimated(viewModel)
} BE
- in FeedViewAdapter:
- FeedImagePresenter<FeedImageCellController, UIImage>
- in LoadResourcePresentationAdapter:
- add extension to LoadResourcePresentatioAdapter conforming to FeedImageCellControllerDelegate
func didRequestImage() {
    loadResource()
}
func didCancelImageRequest() {
    cancellable?.cancel()
} BE
in FeedViewAdapter:
- replace the FeedImagePresenter with the new generic
LoadResourcePresenter(
    resourceView: WeakRefVirtualProxy(view)
    loadingView: WeakRefVirtualProxy(view)
    errorView: WeakRefVirtualProxy(view)
    mapper: UIImage.init(data:)
)
- add ResourceLoadingView and ResourceErrorView conformance to the FeeImageCellController
public func display(_ viewModel: ResourceLoadingView) {
    cell?.feedImageContainer.isShimmering = viewModel.isLoading
}
public func display(_ viewModel: ResourceErrorViewModel) {
    cell?.feedImageRetryButton.isHidden = viewModel.message == nil
}
- UIImage.init(data:) has an error
- if the image fails to be mapped it should show the retry button 
- in the LoadResourcePresenter:
- prublic typealias ... () throws -> ... 
- in the LoadResourcePresenterTests:
T) test_didFinishLoadingWithMapperError_displaysLocalizedErrorMessageAndStopsLoading
let (sut, view) = makeSUT(mapper: { resource in 
    throw anyError()
}
sut.didFinishLoading(with: "resource")
XCTAssertEqual(view.messages, [
    .display(errorMessage: localized("GENERIC_CONNECTION_ERROR")), 
]
- in LoadResourcePresenter 
public func didFinishLoading(with resource: Resource) {
    do {
        resourceView.display(try mapper(resource)
        laodingView.display(Resou...)
    } catch {
        didFinishLoading(with: error)
    }
} (EssentialFeed scheme) TS
[display error on mapper error] only commit this
- back to the FeedViewAdapter:
mapper: { data in 
    guard let image = UIImage(data: data) else {
        throw InvalidImageDataError()
    }
    return image
}
private struct InvalidImageDataError: Error {} TF
- in FeedIamgeCellController:
func view...
cell?.descriptionLabel.text = viewModel.description
cell?.onRetry = delegate.didRequestImage (add this line)
public display(_ viewModel: FeedImageViewModel<... {} (empty this func) TS
- add Cancellable = nil (LoadResourePresentationAdapter)
[replace FeedImagePresenter with LoadResourcePresenter]
- clean the FeedImagePresenter (keep only the map func)
- remove FeedImageView
- update FeedImageViewModel (only location and description related things - remove generic Image)
- fix FeedImagePresenterTests (only test_map... remove generic)
- in FeedImageCellController (remove FeedImageView and generic for FeedImageViewModel)
- remove public display(_ viewModel: FeedImageViewModel<... {} (EssentialFeed) TS
- (CI_iOS) BE
- in FeedSnapshotTests:
- remove generic from FeedImageViewModel
- private extension FeedViewController..
...FeedImageCellController(viewModel: stub.viewModel, ...
private class ImageStub..
    let image: UIImage?
    init ..
        self.viewModel =
        self.image = image
...didRequest...
controller?.display(ResourceLoadingViewModel(isLoading: false)
if let image = image {
    controller?.display(image) 
    controller?.display(ResourceErrorViewModel(message: .none)
} else {
    controller?.display(ResourceErrorViewModel(message: "any")
}
- now we need to send all the necesary messages to the "views" in this case the FeedImageCellController
- (EssentialFeediOS) TS
- (EssentialApp) TF
- delete FeedImageDataPresentationAdapter
- in FeedViewAdapter remove generics from the FeedIamgePresenter
[remove unused FeedImagePresenter logic]
- create typealiases for the adapter to shorten the code (in FeedUIComposer and FeedViewAdapter)
[add type aliases to shorten type definitions with generics]
[move UIImage creation to a tryMake extension]
- add EssentialFeedTests/Image Comments Presentation folder (after Image Comments API)
- create ImageCommentsPresenterTests (copy and paste from FeedPresenterTests)
- remove the map test replace FeedPresenter to ImageCommentsPresenter and ""
- "IMAGE_COMMENTS_VIEW_TITLE"
- table = "ImageComments"
- create EssentialFeed/Image Comments Presentation (after Image Comments API)
- create Image Comments Presentation/ImageCommentsPresenter (copy and paste from FeedPresenter) BS
- create Image Comments Presentation/ImageComments.strings
- "IMAGE_COMMENST_VIEW_TITLE" = "Comments";
- bundle Self.self "Title for the image comments view"
[add image comments title]
- create EssentialFeedTests/Image Comments Presentation/ImageCommentsLocalizationTests
- copy and paste from SharedLocalizationTests TF
- table = "ImageComments" bundle(for: ImageCommentsPresenter.self (import EssentialFeed)
- add the localized versions TS 
[localize image comments title]
- the idea now is to add the viewmodel model etc
- in ImageCommentsPresenterTests: 
T) test_map_createsViewModels() {
    let now = Date()
    let comments = [
        ImageComment(id: message: "a message", createdAt: now.adding(minutes: -5),
         username: "a username"
    ] "another message", "another username" now.adding(days: -1)
}
- in FeedCacheTestHelpers
extension Datae {
    func adding(minutes)..
    func adding(days)..
}
- move this extension to the SharedTestHelpers BS
T) test_map_createViewModel ..
let viewModel = ImageCommentsPresenter.map(comments)
XCTAssertEqual(viewModel.comments, [
    ImageCommentViewModel(
        message: "a message",
        date: "5 minutes ago",
        username: "a username"
    ), idem "1 day ago"
]
in ImageCommentsPresenter:
public struct ImageCommentsViewModel: Equatable {
    public let comments: [ImageCommentViewModel]
}
public struct ImageCommentViewModel { 
    public let message: String
    public let date: String
    public let username: String
    create init
}
public static func map(_ comments: [ImageComment]) -> ImageCommentsViewModel {
    ImageCommentsViewModel(comments: [])
} TF
... map { comment in
    let formatter = RelativeDateTimeFormatter()
    return ImageCommentViewMode(
        message: comment.message,
        date: formatter.localizedString(for: comment.createdAt, relativeTo: Date()),
        username: comment.username
} TS
[map ImageComments into ImageCommentsViewModels]
- but the test depend on locale, calendar, language etc
- inject all of these to run in any environment
- so, in the test
T) test_map..
let now = Date()
let calendar = Calendar(identifier: .gregorian)
let locale = Locale(identifier: "en_US_POSIX"
... viewModel ImageCommentsPresenter.map(
    comments,
    currentDate: now,
    calendar: calendar,
    locale: locale
)
- add the parameters to the map func with defaults (.current)
- set the formatter calendar, locale and use the currentDate TS
- test with other local "pt_BR" TF hà 5 minutos, hà 1 dia TS
- restore english version
[inject currentDate, locale, and calendar to make tests reliable in any locale]
- inject calendar in the adding minutes and day helpers (use this in the test)
[inject calendar to make tests reliable]
- in FeedUIComposer
private typealias FeedPresentationAdapter = LoadResourcePresentationAdapter<[FeedImage], FeedViewAdapters>
- get rid of Presenter you can use the viewModel initializer instead e.g.
public struct FeedViewModel {
    public let feed: [FeedImage]
    
    public init(feed: [FeedImage]) {
        self.feed = feed
    }
} and passs to the mapper this init
- other way of handling the strings files is to have only one in the composition root and inject
- it with contruction injection when instanciating the types 
- 
```

### 3 - 1) Part 1 - Adding a feature-specific UI without duplication
```
- the idea is to have a generic ListViewController that can handle a collection of CellController s (protocol)
- then each case would implement the CellController protocol with the specific needs for each case
- in FeedViewController:
- create the CellController (public protocol
- find and replace (this file) FeedImageCellController to CellController 
- add the methods that it needs (func view(in: UITableView) -> UITableViewCell, preload, cancelLoad)
- make ImageCellController implement CellController (make methods public because it's a public protocol)
- (EssentialApp) TS
[add CellController protocol in preparation to support any cell controller type]
- rename FeedViewController -> ListViewController
[rename ...]
- get rid of the protocol FeedViewControllerDelegate (all protocol with one method can be replaced with a closure)
public var onRefresh: (() -> Void)?
- fix issues
- LoadResourcePresentationAdapter used to conform to that protocol (not needed anymore)
- fix makeFeedViewController (remove delegate) compose the onReresh directly (presentationAdapter.loadResource)
[replace FeedViewControllerDelegate with a closure]
- reorder new shared components
- create EssentialFeediOS/Shared UI (first folder) 
- /Controllers/ListViewController
- /Views/ErrorView 
- /Views/Helpers/UIRefreshControl+Helpers, UITableView+Dequeueing, UITableView+HeaderSizing
- (also we can have shared storyboard and shared assets)
[move Shared UI to new folder]
- create EssentialFeediOSTests/Shared UI (below helpers)
- create Shared UI/ListSnapshotTests
- move the test_emptyFeed import EssentialFeediOS @testable import EssentialFeed
- copy makeSUT and cut emtpyFeed TF because of the snapshot files loaction
- create Shared UI/snapshots folder (move the images needed)
- rename to test_emptyList and helper emptyList "EMPTY_LIST_light" "EMPTY..", [Cellcontroller]
- move the test_feedWithErrorMessage (repeat the procedure) listWithError, "LIST_WITH"
[extract shared ListViewController snapshot tests]
- the idea is to test drive the new UI with the snapshot tests
- create EssentialFeediOSTests/Image Comments UI/ImageCommentsSnapshotTests (below Shared UI)
- copy test_feedWithContent -> listWithComments
- sut.display(comments())
- copy the makeSUT and feedWithContent (rename to comments)
- instead of returning an ImageStubs we can return CellControllers
- replace ImageStubs array with CellController
model: ImageCommentViewModel( message: ""The East Side ..", date: "1000 year ago", username: "a long long long username"
- create other with ""East Side Gallery.. " "10 day ago" "a username"
- "nice" "1 hour ago" "a."
- create EssentialFeediOS/Image Comments UI(below Shared UI)/Controllers/ImageCommentCellController
- public class (import EssentialFeed) conforming to CellController, init model keep a reference to the model
- return an empty cell to avoid compile error
- "IMAGE_COMMENTS_light" "IMAGE_COMMENTS_dark"
- what about the storyboard? -> "ImageComments"
- create Image Comments UI/Views/ (below controllers) /ImageComments.storyboard
- copy the Feed storyboard (it is hard to do it - but there is a trick) copy and paste the xml content (using diff button)
- remove the cell
- change assert to record
- copy the snapshot to EssentialFeediOSTests/Image Comments UI/snapshots
- don't like the fact that the record is not failing when run again
- in XCTCase ... func record ... do {..  XCTAssert("Record succeded - use `assert` to compare the snapshot from now on.")}
[add XCTFail to remind us to call assert after recording a snapshot]
- in ImageCommentsCellController return a ImageCommentCell
- create ImageCommentCell (copy from FeedImageCell)
- need three labels massageLabel, usernameLabel, dateLabel
- now: 
let cell = ImageCell = tableView.dequeueReusableCell
cell.messageLabel = model.message
cell.usernam...
return cell 
- Crash (could not dequeue cell)
- in storyboard set the identity and reusable identifier
- set the labels (hook them) TF (but generate the snapshots)
- embed the top one in a stakc view and the result with the bottom one in other stack view
- pin the outer stack to the super view (all) (0,0,0,0) contraint to the margin = true
- pin the inner stack to the super view (left and right) (0,0)
- comments label lines = 0
- the top labels are fighting now for the space (error)
- date always visible -> content hugging priority horizontal = 250, compression resistance = 751
- username -> content hugging priority horizontal = 252, compression resistance = 749, bold
- date align right the date, secondary label color 
- outter stack view spacing = 8, inner stack view spacing = 8
- take a snaphot then make user name longer to see it cropping
- revert record with assert  
[implement Image Comments UI]
- with swift UI have a live preview for developing when you are happy take a snapshot and then automate regression testing
- 
```

### 3 - 2) Part 2 - Decoupling feature-specific UI from the Shared module
```
- the ImageCommentCellController has two unused methods preload and cancelload
- violation of the interface segregation principle (empy implementations)
- simple way to solve this to add empty implementations to a public extension (like optionals) TS
[add default implementation for optional methods in the CellController protocol]
- the idea now is to replace the CellController protocol with common abastractions given by UITableView apis
- make a typealias CellController that conforms to UITableViewDataSourcePrefetching & ..Delegate & ..DataSource
- when creating a cell we can get the cellController and call controller.tableView(tableView, cellForRow:..)
- when prfetching repeat the same
- in cancelCellControllerLoad.. we get the controller and then set to nil in the loadingControllers and return it (?)
- rename method with removeLoadingController
- now in didEndDisplaying.. we can get the controller from the removeLoadingController and call the same method (dideEn..)
- in cancelPrefetching... for each indexPath we get the controller and call cancelPref...
- now ImageCommentCellController needs to implement the three protocols (to implement these olso need to be NSObject)
- number of rows 1
- cellForRow copy the existing cell creation
- prefetch left empty
- now repeat the same with FeedImageCellController
- number of rows 1
- cell for row idem
- in prefetch call didRequestImage
- in didEndDisplaying call cancelLoad (now it can be private)
- in cancelPrefetching.. call cancelLoad 
- now the cellController controls the whole lifecycle of the cell (the list view controller only send the messages) 
- (EssentialFeediOS) TS (EssentialApp) TS
- move implementations to extensions CellController and ResourceView, ResourseLoadingView, ResourceErrorView
[replace custom CellController protocol with a composition of the UITableViewDataSource/Delegate/Prefetching, so we can decouple other modules from the Shared UI module]
- now we don't have the dependencies on the shared method but we have empty methods implementations
- again a violation of the interface segregation priciple (we could repeat the same of extension with empty methods)
- but there is a better solution to do this intead of using protocol composition into one type
- compose them into a type that hold three types one for each implementation
- a type that has three instances each one conforming to each protocol
- this can be achieve using a tuple: 
- public typealias CellController = (dataSource: UITableViewDataSource, delegate: UITab..?, dataSourcePrefetching: ..?)
- fix issues .dataSource ds (rename - the shortes the scope the shortest the name can be)
- .delegate dl, dataSourcePrefetching dsp
- we cannot implement a tuple - instead conform to the protocol we care about (delete the not used method)
- FeedImageCellController: UITableViewDataSource, ..., ...
- ImageCommentCellController: UITableViewDataSource
- BE in FeedViewAdapter return the tuple CellController(view, view, view) (EssentialApp) TS
- (EssentialFeediOS) BE
- in ImageCommentsSnapshotTests:
- comments(rename to commentsControllers) -> [ImageCommentsCellControllers] 
private func comments() -> [CellController] {
    commentsContollers().map { CellController($0, nil, nil) }
}
- in FeedSnapshotTests: 
func display(_ stubs: [])
let cells = [CellController] = ...
return CellController(cellController, cellController, cellController) TS
- it worked but it's annoying to pass three times the same instance
- change CellController to be a struct (let dataSource etc..)
- create public init (_ dataSource: .. & .. & ..) 
- that implements all of the protocols 
- now we can pass in FeedSnaphotTest only one cellController
- for the case that only implement one protocol:
public init(_ dataSource: UITableDataSource) {
    self.dataSource = dataSource
    self.delegate = nil
    self.dataSourcePrefetching = nil
} 
- make the fixes TS
- move the CellController to its own file (import UIKit)
[replace protocol composition in a single type with a struct composition to prevent forcing clients to implement methods they don't care about]
- there is still a problem: the error view is duplicated (we can compose storyboards like youtube video)
- the other solution is to configure the error view in code (snapshots test will check if they are the same)
- in ErrorView: 
- remove the outlet and change the label to be lazy 
- textColor white, textAligment center, numOfLines 0, font systemFont(size 17)
public override init(frame: CGRect) {
    super.init(frame: frame)
    configure()
}
required init(coder: NSCoder) { super.init(coder: coder) }
- extract the code perform in awakeFromNib (hideMessage) call it also in hideMessageAnimated
private func configure() {
    backgroundColor = .errorBackgroundColor 
    configureLabel()
    hideMessage
}
private func configureLabel(){
    addSubView(label)
    label.translateAutoRe... = false
    NSLayoutContraints.activate([
        label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
        traling 8 invert the order
        bottom top 
    ])
}
extension UIColor { static var ..}
```

### 3 - 3) Part 3 - Creating UI Programmatically, Memory Graph Debugger, Dynamic Type, and Diffable Data Sources
```
- in ListViewController: 
- private(set) public var errorView = ErroView() - fix issues
- create func configureErrorView (private) and call it in viewDidLoad
let container = UIView()
container.backgroudnColor = .clear
container.addSubview(errorView)
(add same code to pin it to the parent without constant)
tableView.tableHeaderView = container
- remove error views from storyboards (EssentialApp) BE fix issues TS
- (EssentialFeediOS) TS
- run the app and add a fake error (LisViewController display ..)
- tapping on it it didn't dismisse it we should have a test to catch this
- in FeedUIIntegrationTests:
T) test_tapOnErrorView_hidesErrorMessage()
copy from test_loadFeedCompletion_rendersErrorMessageOnErrorUntil..
sut.simulateErrorViewTap()
XCTAssertEqual(sut.errorMessage, nil)
- in FeedViewController+TestHelpers:
func simulateErrorViewTap {
    errorView.simulateTap() -> but its need to be a button
}
- in ErrorView: change it to be a UIButton
..configure() { addTarget(self, action: #selector(hideMessageAnimate), for .touchUpInside) 
a button is much more testable and provide a better user experience (EssentialApp) TS
- instead of adding a label we can use the label that the button already have
- cut the label creating code, delete label and paste it in configureLabel (replace label with titleLabel)
- remove autolayout but add the contentEdgeInsets = .init(top: 8, ...
- fix message .. title(for: .normal), showAnimated and hideMessage .. setTitle(message, for: .normal) 
(EssentialApp) TS (EssentialFeediOS) TF comparing the images there is a hugh diference in the top
- set the contentEdgeInsets to 0 0 0 0 (then change to -2.5 0 -2.5 0) the button and set to 8 when showing a message
- run the app - the header is not updating - when updating the table view header you need to manually update the frame 
- when tapping the error view we need to update the header but there is no way for the listController to know
- in ErrorView: add a callback 
- public var onHide: (() -> Void)? call it in hideMessage
in ListViewController:
configureErrorView ..
errorView.onHide = { [weak self] in self?.tableView.sizeTableHeaderToFit() } 
but its not animated -> add self.tableView.beginUpdates() ... self.tableView.endUpdates()
(EssentialApp) TF loader spy should have been deallocated some times it passes sometime it doesnt
- in FeedUIIntegrationTests:
- add a breakpoint in the trackForMemoryLeaks
- run the tests and the po the instance
- if running the test in isolation it doesn't happen
- when catch then open the memory debugger EssentialAppTests -> LoaderSpy
- the cell is holding a refernce to it -> serach the cell and the closure onRetry 
in FeedImageCellController:
cell?.onRetry = { [weak self] in self?.delegate.didRequestImage() }
- it's not a retain cicle but because of the animation it is retaining an instance for longer than it should
[weakify self within onRetry closure to prevent cell from holding strong references to other components]
- remove awakefromnib func
- change the hideMessageAnimated to be @obj (EssentialApp) TS, (EssentialFeediOS) TS
[configure ErrorView programmatically so we don't duplicate layout logic in storyboards]
- in ListSnapshotTests: 
- remove storyboard used to create a ListViewController TF
- in ListViewController: viewDidLoad -> tableView.separatorStyle = .none (not want this)
- add this instaed in the makeSUT of the listsnpashottests
[run ListSnapshotTests without storyboard]
- the idea is to use dynamic types
- in ListSnapshotsTests test_listWithErrorMessage: 
- add a new assertion passing a contentSize (modify the iphone8 func) 
[enable content size category config when taking a snapshot] commit only this
- add LIST_WITH_..light_extraExtraExtraLarge record, drag the snapshot to the project
- in ErroView, configureLabel titleLabel?.font = .preferedFont(forTextStyle: .body) and adjustFontFor.. = true
- retake all snapshots 
- in ImageCommentsSnapshots: add new one and re record all and drag to the project
- set dynamic fonts in storyboard username headline, date subhead, message body (automatically adjust font)
- in FeedSanpshots repeat the same, add test, change fonts, record drag etc
- location subhead ,description body
[replace hardcoded fonts with dynamic fonts]
- the idea is to update the table but only the part that changed (diffable data source)
- in ListViewController:
- replace tableModel with private lazy var dataSource: UITableViewDiffableDataSource<Int, CellController> = {}()
- in CellController add extensions conforming to Equatable and Hashable
- add let id: AnyHashable (could add also a default value with UUID)
- public static func func == (lhs: ...) { lhs.id == rhs.id (equatable) }
- public func hash(into: hasher: inout Hasher) { hasher.combine(id) 
- in ListViewController: dataSource... { 
    .init(tableView: tableView) { (tableView, index, controller) in -copy cell creating code-}
- use controller directly and index
- remove laodingControllers
- in display (cellControlle..
    var snapshot = NSDiffableDataSourceSnapshot<Int, CellController>()
    snapshot.appendSections([0])
    snapshot.appendItems(cellcontrollers, toSection: 0)
    dataSource.apply(snapshot)
- this will check what changed and apply what it's necessary 
- remove numberOfRowsInSection and cellForRowAtIndexPath
- in viewDidLoad tableView.dataSource = dataSource; configureError...
- remove removeLoadingControlles
- cellController(at *old forRowAt* indexPath  .. { dataSource.itemIdentifier(for: indexPath) }
- return an optional CellController
- use this method in all places where a cellController is needed BE
- in FeedViewAdapter: return CellController(id: model, view) the FeedImage model is already Hashable
- (EssentialApp) TF (26) 
- in FeedViewController+TestHelpers:
- numberOfRenderedImageViews... { tableView.numberOfSections == 0 ? 0: tableView.numberOfRows(inSection: feedImagesSec..}
- to resolve the out of bound issue
- in FeeUIIntegraionTests: the diffaible datasource is requesting the image before the image is visible 
- in LisViewController dataSource .init...  print("\(index.row)" loads a bunch of cell 
- (we request the image as we create the cell)
- this can be because of wrong estimate hight -> set the table view estimate row hight to 580
- if you cannot estimate the row height is to move the loading of the image to the 
- othe options is to in FeeImageCellController: move delegate.didRequestImage to new willDisplay cell {  } 
- even it is loading two images ahead of time - one solution is to set in the test the frame of the table view to small
- value test_feedImageViewLoadingIndicator... sut.tableView.frame = CGrect.. 0 0 1 1
- move this to a helper override loadViewIfNeeded... { super. ..  sut.tableView...} in FeedViewController+TestHelpers
- (EssentialApp) TS (EssentialFeediOS) BE in ImageCommentsSnapshotTests comments .. id: UUID() and FeedSnapshop also
- snapshot dont match anymore there is no labels etc
- in ListViewController:
viewDidLayout... 
public override func traitCollectionDidChange
    if previous?.preferedContentSizeCategory != traitCollection.preferr
        tableView.reloadData() run the app is works
- (EssentialFeediOS) TS (EssentialApp) TS
[use diffable data source to only reload cells when needed]
[set data source default row animation to fade]
[add `UIView.makeContainer` helper]
[extract table view configuration into a helper method]
update 1
[use applySnapshotUsingReloadData on iOS 15+ to maintain the same data source behavior we have on iOS 14 and before.] 
update 2 3 (not implemented yet)
[configure Error View with the new UIButton.Configuration APIs]
```

### 4 - 1) [Image Comments Composition] Navigation and Feature Composition
```
[rename file] (ListViewController+TestHelpers)
[reorder test] (FeedUIIntegrationTests)
- for simple views (dont require complex dependencies) you can present them directly
- for example in the ListViewController display(error) func
if let error = viewModel.message 
    let alert = UIAlerController(title: nil, message: message, preferredStyle: .alert) 
    present(alert, animated: true) 
- other example if the FeedImageViewModel would have access to all the comments (array of comments)
- when selecting a row we could get the index and pass the comment to the comments view and navigate 
- one argument agaist this is that it would need to know if it is in a navegation controller or presented modally
- to solve this we can use the show method (it will handle the navigation for us) presented or pushed in a nav controller
- other api is showDetailViewController
- olso you could set up the dependencies in the the prepare for segue
- in generic view controllers we could not have this coupling
- the idea is to handle navigation in the composition root
- so we start with an integration test for the feed comments
- create EssentialAppTests/CommentsUIIntegrationTests (last)
- copy and past from the FeedUIIntegrationTests (but it uses a bunch of helper methods declared in test extensions!)
- so we could make it a subclass of it (remove the final and override the methods) (editor fix all issues) TS
- remove all image specific tests (not the last one test!) remove also makeImage helper
- in makeSUT change to CommenstUIComposer.commentsComposedWith(commentsLoader: loader.loadPublisher)
- create the CommentsUIComposer (below the FeedUIComposer)
- copy and paste from it and change the names (only the needed for the test)
- for the case of imageLoader replace it with a closure {_ in Empty<Data, Error>.eraseToAnyPublisher() } TS
[duplicate FeedUIComposer as CommentsUIComposer]
- the idea is to go one by one removing the override for each test and after all are done remove the subclassing
T) test_commentsView_hasTitle
- add new commentsTitle helper (FeedUIIntegrationTests extension?) TF
- in the CommentsUIComposer pass the right title (ImageComments..) TS
[set comments title]
T) test_loadCommentsActions_requestCommentsFromLoader
- loaderspy has loadFeedCallCount (we could create a generic one or create a new one)
- create a new LoaderSpy: (in CommentsUIIntegrationTests) import Combine
- rename commentsRequests, loadCommentsCallCount, 
- rename the simulateUserInitiatedFeed.. to simulateUserInitiatedReload (because it is generic now)
[load actions request comments]
T) test_loadingCommentsIndicator_isVisibleWhileLoadingComments
- rename completeFeedLoading to completeCommentsLoading also completeCommentsLoadingWithError
[loading indicator is visible while loading comments]
T) test_loadCommentsCompletion_rendersSuccessfullyLoadedComments
- rename to makeComment(message(not optional give a default value): username:) -> ImageComment, createdAt: Date()
- remove all cases representing optional situations from the test
- rename comment0 comment1, 
T) test_loadCommenstCompletion_rendersSuccessfullyLoadedEmptyCommentsAfterNonEmptyComments
- rename to comment (use only one)
T) test_loadCommentsCompletion_doesNotAlterCurrentRenderingStateOnError
- rename to comment
- refactor completeCommentsLoading and LoaderSpy FeedImage -> ImageComments
- follow the compiler to CommentsUIComposer, rename to CommentsPresentationAdapter, 
- the ImageCommentsPresenter.map takes more than one parameter (with dafault values) so we need to wrapped in a closure
- to use call it there  
- in CommentsUIcomposer create a new CommentsViewAdapter (based on the FeedViewAdapter)
- remove imageLoader related code, ImageCommmentsViewModel, remove for now the code to display
- rename to makeCommentsViewController and commentsController, in makeCommentsViewController rename to controller
- storyboard is ImmageComments
- back to the tests:
- create a new assertThat (below makeSUT, makeComment) delete all and add
XCTAssertEqual(sut.numberOnfRenderedComments(), comments.count, "comments count"
- in ListViewController+TestHelpers create numberOfRenderedComments, commentsSection
- split the ListViewControllers extensions in separate extensions what is feed specific and comments specific
- add assertThat specific information for the compiler (EssentialApp) BS but TF we are not displaying the comments yet
- in CommentsViewAdapter display
contoller?.display(viewModel.comments.map { viewModel in 
    CellController(id: viewModel, UITableViewController()) - for now, because it implementes data source protocol
} BE 
- id needs to be Hashable so we can make ImageCommentViewModel Hashable (it is just data) BS TS
- we are only testing the count so far
- in assertThat:
let viewModel = ImageCommentsPresenter.map(comments) -> to be able to get the date already converted to string
viewModel.comments.enumerated().forEach { index, comment in 
    XCTAssertEqual(sut.commentMessage(at: index), comment.message, "message at \(index)", file...)
    XCTAssertEqual(sut.commentDate(at: index), comment.date, "date at \(index)", file...)
    XCTAssertEqual(sut.commentUsername(at: index), comment.username, "username at \(index)", file...)
}
- in ListViewController+TestHelpers:
- func commentMessage(at row: Int) -> String? { commentView(at: row).messageLabel.text } 
- create new func commentView (from feedImageView) with commentsSection, ImageCommentsCell, as? ImageCommentsCell, 
- numOfre.., repeat the same for commentDate and commentUsername TF
- in CommentsUIComposer CommenstViewAdapter:
CellController(id: viewModel, ImageCommentsCellContrller(model: viewModel)) TS
[render comments]
T) test_loadCommentsCompletion_dispatchesFromBackgroundToMainThread
[dispatches from background to main queue]
T) test_loadCommenstCompletion_rendersErrorMessageOnErrorUntilNextReload
T) test_tapOnErrorView_hidesErrorMessage
- remove subclassing from FeeUIIntegrationTests BE
- move the helpers from FeedUIIntegration+Localization (delete file) to the SharedTestHelpers TS
[move localization helpers to shared scope] only the change in the project]
[remove feed references from comments integration tests]
- now we have a ui composer that will instantiate the whole object graph
- the idea now is to probe that the loading operation is cancelled (it is already cancelled when going back)
- in CommentsUIIntegrationTests:
T) test_deinit_cancelsRunningRequest
var cancelCallCount = 0

var sut: ListViewController? = CommentsUIComposer.commentsCompsedWith(commmentsLoader: {
    PassthroughSubject<[ImageComment], Error>()
        .handleEvents(receiveCancel: {
            cancelCallCount += 1
        }).eraseToAnyPublisher()
})

sut?.loadViewIfNeeded()
weak var weakSUT = sut (after TF)
XCTAssertEqual(cancelCallCount, 0)
sut = nil
XCTAssertNil(weakSUT) (after TF)
XCTAssertEqual(cancelCallCount, 1)
- TF -> add code to confirm that the instance is deallocated both last assertions failed TF
- this means that some global state is holding a reference
- but it is deallocated by the time the track for memory leak test is excuted, it could be an autorelease issue
- set a breakpoint in the last assertion (autorelease pool holding a reference to it)
- all the things in an autorealease pool will liberate the objects in the next cycle when the test finishes
- if we want to control the autorelease lifetime we can create our own autoreleasepool
autoreleasepool { sut = ... } TS
[proves request is canceled on comments view deinit]
- if more tests would need to check the cancel call cound maybe it would be a good idea to move 
- the tracking to the loader spy
```

### 4 - 2) Handling selection and navigation in the Composition Root
```
- the idea is to notify the composition root via a closure and someone listening to this 
- will use the CommentsComposer to create the Comments view and push it in the navigation controller
- in FeedUIIntegrationTests:
T) test_imageSelection_notifiesHandler() (below test_feedView_hasTitle)
- copy and paste code from test_loadFeedCompletion_rendersSuccessfullyLoadedEmptyFeedAf...
- create two images, load view, present images on screen 
var selectedImages = [FeedImage]()
let (sut, loader) = makeSUT(selection: { selectedImage.append($0) })
simulateTapOnFeedImage(at: 0)
XCTAssertEqual(selectedImages,[image0])
simulateTapOnFeedImage(at: 1)
XCTAssertEqual(selectedImages,[image0, image1]) 
- in ListViewController+TestHelpers:
- func simulateTapOnFeedImage(at row: Int) {
    let delegate = tableView.delegate
    let index = IndePath(row: row, section: feedImageSection)
    delegate?.tableView(tableView, didSelectRowAt: indexPath)
}
- back in the test:
- pass the selection closure to the makeSUT
.. selection: @escaping (FeedImage) -> Void (give a default value)
- forward the selection to the FeedUIComposer (also give a default value)
- in FeedUIComposer:
- add the selection handler to the feedComposedWith func TF
- the question now it which component has the feed images?
- in ListViewController:
- when tableView(didSelectRowAt) received, forward the message to the delegate
let dl = cellController(at: indexPath)?.delegate
dl?.tableView(tableView, didSelectRowAt: indexPath)
- in FeedImageCellController:
- when receives this message (need to forward too):
public func tableView(... didSelectedRow.. ) {
    *
}
- In FeedImageCellController, add a method to the FeedImageCellControllerDelegate: 
func didSelectImage() but this force the protocol implementations to handle selection!
- instead in FeedImageCellController pass a selection closure (without param) in the init method
- (add a sotored property)
- now we can call the selection closure in * BF
- in FeedViewAdapter: 
- ... selection: { [selection] in
    selection(model)
}
- pass a selection closure also in the FeedViewAdapter init (stored in a property also)
- in FeedUIComposer:
- pass the selection to the FeedViewAdapter selection TS
[notifies selection handler on image selection]
- the idea now is to write an acceptance test to test the navigation
- in FeedAcceptanceTests:
T) test_onFeedImageSelection_displaysComments
let comments = showCommentsForFirstImage() (comments is the ListViewController - represent the UI)
XCTAssertEquals(comments.numberOfRenderedComments(), 1)
- create the helper showCommentsForFirstImage -> ListViewController
    let feed = launch(httpClient: .online(response), store: .empty)  (launch the app online)
    feed.simulateTapOnFeedImage(at: 0)
    RunLoop.current.run(until: Date()) (when pushing it do it animated, so to wait for the result)
    let nav = feed.navigationController
    return nav?.topViewController as! ListViewController TF
- in makeData(for url)..
case "/essential-feed/v1/image/{image-id}/comments"
    return makeCommentsData()
private func makeCommentsData() -> Data {
    return try! JSONSerialization.data(withJSONObject ["items": [
        "id" : UUID().uuidString
        "message": makeCommentMessage()
        "created_at": "2020-05-20T11_24:59+0000",
        "author": [
            "username": "a username"
        ]
    ]])
}
private func makeCommentMessage() -> String {
    "a message"
}
- in the test:
XCTAssertEqual(comments.commentMessage(at: 0), makeCommentMessage() TF
- the idea now is to implement the navigation (the navigation controller is in the scene delegate)
- in SceneDelegate:
feedComposedWith.. selection: showComments
private func showComments(for image: FeedImage) {
    let url = URL(... /essential-feed/v1/image/\(image.id)/comments)
    let comments = CommentsUIComposer.commentsComposedWith(
        commentsLoader: makeRemoteCommentsLoader(url: url)
    *
}
private func makeRemoteCommentsLoader(url: URL) -> () -> AnyPublisher<[ImageComment], Error> {
    return { [httpClient] in 
        httpClient
            .getPublisher(url: url)
            .tryMap(ImageCommentsMapper.map)
            .eraseToAnyPublisher()
    }
}
- extract the navigation controller to a private lazy var (below localFeedLoader)
- private lazy var navigationContrller = UINaviagionController (
    -copy code from before-
)
- use it in configureWindow and showComments 
- * navigationController.pushViewController(comments, animated: true) TS
- private lazy var baseURL = URL(string: "...")
- let url = baseURL.appendingPathComponent("/v1/image/\(image.id)/comments" and "/v1/feed" TS
[show comments on image selection]
- run the app, it's working
- httpClient is only created once and shared across features 
- its not a singleton, it is created once and then injected where needed (singleton life time)
- LocalFeedImageDataLoader is transient life time (only created when needed)
- the url used it may be defined in the Image Comments API module (to not leak details)
- everything that is contract specific can go here
- in Image Comments API
- create ImageCommentEndpoint
public enum ImageCommentEndpoint {
    case get(UUID)
    
    public func url(baseURL: URL) -> URL {
        switch self {
        case let .get(id):
        return baseURL.appendingPathComment("/essential-feed/v1/image/\(id)/comments"Ima)
        
        }
    }
}
- then let url = ImageCommentsEndpoint.get(image.id).url(baseURL: baseURL)
- this can be reapeated for the feed as well
- something we could do to mock the behavior could be 
- var commentsFactory = CommentsUIComposer.commentsComposedWith(commentsLoader:)
 then let comments = commentsFactory(makeRemoteCommentsLoader(url: url)
- repeat the same for feed endopoint
- add test for both cases
[extract endpoint URL creation to the API modules]
- in ListViewController+TestHelpers:
[extract helper methods to remove duplication]
```

### 5) Keyset Pagination with Caching Strategy
```
(this was made before the lecture)
- forward willDisplayCell message
[propagate willDisplayCell delegate method calls]
- refactor init for CellController to use only one with as? for the optional parameters 
[merge CellController initializers]
- create makeImageData0 and makeImageData1 in FeedAcceptanceTests
[improve coverage with distinct image data per index]
- beginning of the lecture
- limit page pagination explained in mentoring session #15
- keyset based (aka  seek method)
- after_key and before_key
- the idea is to start with the UI - we need to add the activity indicator at the bottom - we could add it to the 
- ListViewController 
- (pull to refresh can be disabled in the stotyboard)
- or we can inject it as a CellController
- in FeedSnapshotTests (EssentialFeediOS scheme):
T) test_feedWithLoadMoreIndicator
- create feedWithLoadMoreIndicator (return array of CellController), record FEED_WITH_LOAD_MORE_INDICATOR_light and dark
let loadMore = LoadMoreCellController 
return [CellController(id: UUID, loadMore)]
- create the LoadMoreCellController in production (in Feed UI for now because it's only used there so far)
- is NSObject and UITableViewDataSource, items 1, UITableViewCell, record and grag files to the project
- in LoadMoreCellController: create LoadMoreCell 
private lazy var spinner: UIActivityIndicatorView = {
    let spinner = UI...(style: .medium)
    contenView.addSubview(spinner)
    return spinner
}
- in LoadMoreCellController: ResourceLoadingView extension (same file): add the display func
- in the test call that display func with the proper viewModel (isLoading)
- feedWithLoadMoreIndicator
- to make the spinner start animating instead of calling the spinner directly use a public computed var using a 
- getter and a setter
- cell.isLoading = viewModel.isLoading (add a reference to the cell private stored property) 
- visual test failed: the spinner is not centered    
- center the spinner using code (NSLayoutConstraint.activate) (centerXAnchor, centerYAnchor)
- also contentView.heightAnchor.constraint(lessThanOrEqualToConstant: 40) now it's centered
- but to see other image view cell, in feedWithLoadMoreIndicator:
- create an FeedImageCellController with the last feedWithContent image stub 
- and return the two cell controllers, change to assert TS
- move the LoadMoreCell to the Views folder
[add "Load more" cell controller with loading indicator]
- the idea now is to add the error message
T) test_feedWithLoadMoreError
- use feedWithLoadingMoreError func, FEED_WITH_MORE_ERROR_light, dark and extraExtraExtraLarge (we are using text)
- create the actual feedWithLoadMoreError (copy the previus but display an viewModel (ResourceErrorViewModel)
- "This is a multiline\nerror message"
- add to the extension the ResourceErrorView
- set the error (not yet implemented)
- in LoadMoreCell: add a computed var message String to set and get the message text to a messageLabel text
- create the messageLabel (also a lazy var) UILabel textColor tertiaryLabel, .font = .prefe... .footnote, num of lines 0 
- text alignment center, adjustFontForConten... true
- leading anchor with contentView, trailing, top and bottom all with constant 8 (record and drag files)
- in FeedSnapshotTests: create func feedWith(loadMore: LoadMoreCellController) -> [CellController] 
(use it in previous indicator and error funcs)
[add "Load more" message label]
- now the idea is to write integration tests
- in FeedUIComposer: create struct PaginatedFeed { let feed: [FeedImage], loadMore: (() -> AnyPublisher...)?}
- (this way the UI is decouple from the real implementation it can be page based, etc)
- even it can be a generic Paginated<Item> ... AnyPublisher<Paginated<Item> ..
- move this new data model to the Shared API folder
- but we cannot import Combine to not couple the shared model
- createa a typealias LoadMoreCompletion (Result<Paginated<Item>, Error>) -> Void)
- let loadMore: ((@escaping LoadMoreCompletion) -> Void)? now we don't need to depend on Combine
- change the feedLoader to return a Paginated<Item> 
- In FeedUIIntegrationTests change the feedRequests to handle Paginated<FeedImage> instead, make Paginated public
- remplace it everywhere - in completeFeedLoading create a Paginated(item: feed)
- add a public init to Paginated with a default value of nil to the loadMore closure
- follow the compiler to change it also in FeedUIComposer FeedViewAdapter (display viewModel Paginated<FeedImage>
- change the mapper of FeedViewAdapter to be a closure to forward the items
- also change makeRemoteFeedLoaderWithLocalFallback in sceneDelegate add map (to paginated) and eraseToAnyPublisher TS
[make ...]
- in FeedUIIntegrationTests: 
T) test_loadMoreActions_requestMoreFromLoader (after test_loadFeedActions_requestFeedFromLoader)
- add completeFeedLoading and assert loadMoreCallCount = 0 "expected no requests until load more action"
- then simulateLoadMoreFeedAction "expected load more request"
- in the LoaderSpy add private(set) var loadMoreCallCount = 0 add it in loadMore closure of completeFeedLoading
- in ListViewController + testHelpers: add simulateLoadMoreFeedAction (after simulateFeedImageViewNotNearVisible)
- the idea is to load when the load more cell is going to be visible (separate it into other section)
- section 1 is now the feedLoadMoreSection and send the message to the delegate willDisplayCell
- before get the cell if it exists guard let cell = cell(row: 0, section: feedLoadMoreSection) TF
- in LoadMoreCellController:
- add conformace to UITableViewDelegate and add willDisplay cell ...
- there invoke a callback() stored property (set in the initializer)
- we create the feed in the FeedViewAdapter 
- extract cellcontroller array into a variable 'feed' 
- let loadMore = LoadMoreCellController { _ in viewModel.loadMore?({ _ in }) }
- let loadMoreSection = [CellController(id: UUID(), loadMore)]
- controller?.display(feed, loadMoreSection)
- in ListViewController: 
- public func display(_ sections: [CellController]...) { 
... 
sections.enumerated().forEach { section, cellControllers in 
    snapshot.appendSections([section])
    snapshot.appendItems(cellControllers, toSection: section) 
} TF memory leak -> wekify self TS
[load more...]
- in test_loadMoreActions_requestMoreFromLoader
- add another assertion of loadMoreCallCount to be 1 after simulating load more action
- "Expected no request while loading more"
- in LoadMoreCellController: ... willDisplay
- guard !cell.isLoading else { return } (remove cell parameter name TF never set it to isLoading
- in FeedViewAdapter: add typealias LoadMorePresentationAdapter ... Paginated<FeedIamge> .. FeedViewAdapter
- let loadMoreAdpater = LoadMorePresentationAdapter(loader: viewModel.loadMore) but the adapter spect in the loader
- param a closure that returns a AnyPublisher
- (we need to bridge the closure into the Combine world)
- in CombineHelpers: (at the top)
public extension Paginated {
    var loadMorePublisher: (() -> AnyPublisher<Self, Error>)? {
        guard let loadMore: self else { return nil }
        
        return {
            Deferred {
                Future(loadMore)
            }.eraseToAnyPublisher()
        }
    }
} 
- back in FeedViewAdapter: we can now use the publisher
guard let loadMorePublisher = viewModel.loadMorePublisher else { controller?.display(feed) return }

loadMoreAdapter.presenter = LoadResourcePresenter(
    resourceView: self, 
    loadingView: WeakRefVirtualProxy(loadMore)
    errorView: WeakRefVirtualProxy(loadMore)
    mapper: { $0 })
) TF
- change to let loadMore = LoadMoreCellController(callback: loadMoreAdapter.loadResource) TS
[prevent load more action ...]
- the idea now is to test the case where it need to call load more the second time (it should not be the last one)
loader.completeLoadMore(lastPage: false, at: 0)
sut.simulateLoadMoreFeedAction()
XCT ... 2 "Expected request after load more completed with more pages"

loader.completeLoadWithError(at: 1)
sut.simulateLoadMoreFeedAction()
XCT ... 3 "Expected request after load more failure"

loader.completLoadMore(lastPage: true, at: 2)
sut.simulateLoadMoreFeedAction()
XCT ... 3 "Expected no request after loading all pages"
- in FeedUIIntegrationTests+LoaderSpy
func completeLoadMore(with feed: [FeedImage] = [], lastPage: Bool = false, at index: Int = 0) { ..idem }
func completeLoadMoreWithError(at index: Int = 0)
- we cannot use the feedRequests so create loadMoreRequests update loadMoreCallCount to be the count of requests
- in completeFeedLoading( ... in load more create a publisher to return it before appendin it to loadMoreRequests
- do the same in completeLoadMore ..
- but we cannot used the publisher we need to convert it to a closure   
- in CombineHelpers:
init(items: [Item], loadMorePublisher: (() -> AnyPublisher<Self, Error>)?) {
    self.init(items: items, loadMore: loadMorePublisher.map { publisher in 
        return { completion in //every time this closure is invoked we will:
            publisher().subscribe(Subscribers.Sink(receiveCompletion: { result in
                if case let .failure(error) = result {
                    completion(.failure(error))
                }
            }, receiveValue: { result in 
                completion(.success(result)
            }))
        }
    })
} 
- we use the Subscriber.Sink and Combine will handle the cancellable for us 
- (the subscription will be alive until we complete)
- in the tests use the new loadMorePublisher 
func completeLoadMore(with feed: [FeedImage] = [], lastPage: Bool = false, at index: Int = 0) {
    loadMoreRequests[index].send(Paginated(
        items: feed,
        loadMorePublisher: lastPage ? nil : { [weak self] in
            let publisher = PassthoughSubject<Paginated<FeedItem>, Error>()
            self?.loadMoreRequests.append(publisher)
            return publisher.eraseToAnyPublisher()
        }))
} BE fix name in test TS
[does not ..]
T) test_loadMoreIndicator_isVisibleWhileLoadingMore (we copy the previous one an use it as a guide)
sut.loadViewIfNeeded() 
XCTAssertFalse(sut.isShowingLoadMoreFeedIndicator) "Expected no loading indicator once view is loaded"

loader.copmleteFeedLoading(at: 0) "Expected no loading indicator once loading completes successfully"
X.. False "" 

sut.simulateLoadMoreAction()
X.. True "Expected loading indicator on load more action"

loader.completeLoadMore(at: 0)
X.. False "Expected no loading indicator once user initiated loading completes successfully"

sut.simulateLoadMoreAction()
X... True "Expected loading indicator on second load more action"

loader.completeLoadMoreWithError(at: 1)
X.. False "Expected no loading indicator once user initiated loading completes with error"

- in ListViewController+TestHelpers:
var isShowingLoadMoreFeedIndicator: Bool {
    let view = cell(row: 0, section: feedLoadMoreSection) as? LoadMoreCell
    return view?.isLoading == true
} TS
- add a helper private func loadMoreFeedCell() -> LoadMoreCell? {
    cell(row: 0, section: feedLoadMoreSection) as? LoadMoreCell
} replace previous 2 used cases with this TS
[show..]
- in test_loadFeedCompletion_rendersSuccessfullyLoadedFeed


- after loader.completeFeedLoding(with [image0, image1]
sut.simulateLoadMoreFeedAction()
loader.completeLoadMore(with: [image0, image1, image2, image3], at: 0)
assertThat(sut, isRendering: [image0, image1, image2, image3])

sut.simulateUserInitiatedReload
loader.completeFeedLoading(with: [image0, image1], at: 1)
assertThat(sut, isRendering: [image0, image1]
- in test_loadFeedCompletion_rendersSuccessfullyLoadedEmptyFeedAfterNonEmptyFeed
add this in between existing tests (load only one image first)
sut.simulateLoadMoreFeedAction()
loader.completeLoadMore(with: [image0, image1], at: 0)
assertThat(sut, isRendering: [image0, image1]) 
- in test_loadFeedCompletion_doesNotAlterCurrentRenderingStateOnError
add at the end
sut.simulateLoadMoreFeedAction()
loader.copmpleteLoadMoreWithError(at: 0)
assertThat(sut, isRendering: [image0]
- create func_loadMoreCompletion_dispatches..
sut.simulateLoadMoreFeedAction()
... loader.completeLoadMore
[render..]
- now the idea is to show error message on failure
- in FeedUIIntegrationTests: 
T) testLoadMoreCompletion_rendersErrorMessageOnError (copy from previous)
- add loader.completeFeedLoading, sut.simulateLoadMoreFeedAction() -> error should be nil
- loader.completeLoadMoreRequestWithError -> assert error loadMoreFeedErrorMessage 
- sut.simulateLoadMoreFeedAction -> error should be nil
- in ListViewController+testHelpers:
- add loadMoreFeedErrorMessage return loadMoreFeedCell()?.message TS
[renders ..]
T) test_tapOnLoadMoreErrorView_loadsMore
- copy first part of previous setup 
- sut.simulateLoadMoreFeedAction -> loadMoreCallCount 1
- sut.simulateTapOnLoadMoreFeedError -> loadMoreCallCount 1
- loader.completeLoadMoreWithError, simulateTap.. -> count 2
- in ListViewController+TestHelpers: simulateTapOnLoadMoreFeedError (use table view did select) TF
- in LoadMoreCellController: create didSelect.. { guard !cell.isLoading else { return } callback() } TS
- create a helper function reloadIfNeeded 
[load more..]
- the idea is to implement the API now
- in FeedEndpointTests: 
- XCTAssertEqual(received.scheme, "http", "scheme")
- XCTAssertEqual(received.host, "based-url.com", "host")
- XCTAssertEqual(received.path, "/v1/feed", "path")
- XCTAssertEqual(received.query, "limit=10", "query") [EssentialFeed] TF
- in FeedEndpoint: 
let url = baseURL.appendingPathComponent("/v1/feed")
var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
components?.queryItems = [
    URLQueryItem(name: "limit", value: "10")
] 
return components!.url! TS
- refactor to return components.url! -> safe to force unwrap it because it is static (it would be a programmer mistake)
var components = URLComponents()
components.scheme = baseURL.scheme 
components.host = baseURL.host
components.path = baseURL.path + "/v1/feed" TS
[set ..]
- run the app and see only 10 images
- create a new case getAfter(FeedImage) or case get(after: FeedImage? = nil) (last case will break clients)
- in FeedEndpointTests:
T) test_feed_endpointURLAfterGivenImage() { 
    let image = uniqueImage()
    .. get(after: image)
    ... "limit=10&after_id=\(image.id)", "query"
} TF
- in FeedEndpoint: ... .get(image) .. 
    URLQueryItems(name: "limit", value: "10"),
    image.map { URLQueryItems(name: "after_id", $0.id.uuid }
    ].compactMap { $0 } TS
- if the order change it will brake the test
- change test to XCTAssertEqual(recieved.query.contains("limit=10"), true, "query param"
- and "after_id" TS
[add ..]
- composition
- in FeedAcceptanceTests, test_onLaunch_displayRemoteFeedWhenCustomerHasConnectivity
XCTAssertTrue(feed.canLoadMoreFeed)
- in ListViewController+TestHelpers:
var canLoadMoreFeed: Bool { loadMoreCell() != nil } TF
- in SceneDelegate: ... Paginated(items: $0, loadMorePublisher: { Empty().eraseToAnyPublisher() } TS
- back in the test 
feed.simulateLoadMoreFeedAction()
XCTAssertEqual ... numbOfRen ... 3
...at 0... makeImageData0 ... 2 .... 3
XCTAssertTrue(feed.canLoadMoreFeed)
- create makeImageData2 blue "/image-2"
... case "/essential-feed/v1/feed" where url.query?.contains("after_id") == false: return makeFirstFeedPageData() (rename)
case "/essen.." where url.query?.contains("after_id=XXX_LAST_ID_XXX": return makeSecondPageData()
- create makeSecondFeedPageData witha a new UUID TF
- in SceneDelegate: 
...
.map { [httpClient, baseURL] items in 
    Paginated(items: items, loadMorePublisher: items.last.map { lastItem in 
        let url = FeedEndpoint.get(after: lastItem.id).url(baseURL: baseURL)
        return { [] in
            httpClient
                .getPublisher(url: url)
                .tryMap(FeedItemsMapper.map)
                .map { newItems in 
                    Paginated(items: items + newItems, loadMorePublisher: {
                        Empty().eraseToAnyPublisher()
                    }
                }.eraseToAnyPublisher
            }
        }
    })
} TS
- add a test simulated the load request reaching the end
case "/eseen..." "after_id=LAST_ID_FOR_SECOND_PAGE", makeLastEmptyFeedPageData (returning []) TF
- in SceneDelegate:
- create makeRemoteLoadMoreLoader(items: [FeedImage], last: FeedImage?) -> (() -> AnyPublisher<Paginated<FeedImage>, Error>)? {
    last.map { lastItem in 
    let url = FeedEndpoint.get(after: lastItem.id).url(baseURL: baseURL)
    return { [httpClient] in
        httpClient
            .getPublisher(url: url)
            .tryMap(FeedItemsMapper.map)
            .map { newItems in 
                let allItems = items + newItems
                return Paginated(items: allItems, loadMorePublisher: 
                    self.makeRemoteLoadMoreLoader(items: allItems, last: newItems.last)
            }.eraseToAnyPublisher()
        }
    }
} 
- ... .map { items in 
    Paginated(items: items, loadMorePublisher: self.makeLoadRemoteLoadMoreLoader(items: items, last: items.last)
} TS
[load more..]
- test the caching:
- in test_onLaunch_displaysCachedRemoteFeedWhenCustomerHasNoConnectivity: 
- add onlineFeed.simulateLoadMoreFeedAction()
- onlineFeed.simulateFeedImageViewVisible(at: 2) ...
- XCTAssert(offlineFeed.rende.... at 2 makeImageData2) TF we are caching the pages
- in SceneDelegate: 
- ...
    newItems.last))
}
.caching(to: localFeedLoader)
.eraseToAnyPublisher() (capture the localFeedLoader)
- in CombineHelpers:
extension Publisher {
    ...
    func caching(to cache: FeedCache) -> AnyPublisher<Output, Failure> where Output == Paginated<FeedImage> {
        handleEvents(receiveOutput: cache.saveIgnoringResult).eraseToAnyPublisher()
    }
}
...
private extension {
    ...
    func saveIgnoringResult(_ page: Paginated<FeedImage>) {
        saveIgnoringResult(page.items)
    }
} TS
[cache page results]
- refator in sceneDelegate:
private func makeFirstPage(items: [FeedImage]) -> Paginated<FeedImage> {
    copy code from makerRemote... .map( x ) 
} (use the funciton in the map) TS 

private func makePage(itmes: [FeedImage], lastItem: FeedImage?) -> Paginated<FeedImage> {
    copy code from  but pass the last 
} then 
... 
.map { newItems in 
    (itmes + newItems, newItems.last)
}.map(makePage) (capture makePage)
.caching(to: localFeedLoader) TS
- change makeFirstPage to call makePage and use itmes.last for last TS
- to remove the nested closure:
private func makeRemoteLoadMoreLoader(items: [FeedImage], last: FeedImage?) -> AnyPubliser<Paginated<FeedImage>, Error> {
    let url = FeedEndpoint.get(after: last).url(baseURL: baseURL)
    
    return httpClient
        .getPublisher(url: url)
        .tryMap(FeedItemsMapper.map)
        .map { newItems in 
            (items + newItems, newItems.last)
        }.map(makePage)
        .caching(to: localFeedLoader)
}

private func makePage(items: [FeedItem], last: FeedImage?) -> Paginated<FeedIamge> {
    Paginated(items: items, loadMorePublisher: last.map { last in 
        { self.makeRemoteLoadMoreLoader(items: items, last: last) }
    })
} TS

private func makeRemoteFeeLoader(after: FeedImage? = nil) -> AnyPublisher<[FeedImage], Error> {
    let url = FeedEndpoint.get(after: last).url(baseURL: baseURL)
    
    return httpClient
        .getPublisher(url: url)
        .tryMap(FeedItemsMapper.map)
        .eraseToAnyPublisher()
}
in makeRemoteLoadMoreLoader and makeRemoteFeedLoaderWithLocalFallback use the makeRemoteFeedLoader TS
[extract ..]
- run the app to see how it works add
... makeRemoteLoadMoreLoader ... .map(makePage).delay(for: 2, scheduler: DispatchQueu.main)
- simulate an error
... .delay ... .flatMap{ _ in Fail(error: NSError()} when tapping it shows a selection background
in LoadMoreCellCotroller: cell for row
cell.selectionStyle = .none
[remove ..] (only the selection style change)
- in tableView willDisplay: 
private var offsetObserver: NSKeyValueObservation?
offsetObserver = tableView.observe(\.contentOffset, options: .new) { [weak self] (tableView, _) in 
    guard tableView.isDragging else { return }
    
    self?.reloadIfNeeded()
}
in didEndDisplayingCell 
    offsetObserver = nil -> now it reload also when scrolling
[automatically.. ]
- remove the fail code for testing in the scene delegate
- to prevent keeping all the items in memory: 
- remove the items parameter from makeRemoteLoadMoreLoader and 
... makeRemoteFeedLoader(after: last)
    .flatMap { [localFeedLoader] newItems in
        localFeedLoader.loadPublisher().map { cachedItems in
            (newItems, cachedItems)
        }
        .map { (newItems, cachedItems) in
            (cachedItems + newItems, newItems.last)
        }.map(makePage)
    }
- this is a memory optimization that will depend on the case
- the flatMap can be replaced by 
... .zip(localFeedLoader.loadPublisher()) TS
- also we could invert the order:
localFeedLoader.loadPublisher()
    .zip(makeRemoteFeedLoader(after: last))
    .map { (cachedItems, newItems) in
        (cachedItems + newItems, newItems.last)
    }.map(makePage)
    .caching(to: localFeedLoader)
[fetch]
- 
```
