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
- add CoreDataFeedStore model Feed Cache/FeedStore (add file Core Data)
- add entities 
- set Codegen to Manual/None (for the entities)
- add relationships cache <-> feed (with inverse feature)
[add CoreDataFeedStore data model]
- add ManagedCache and ManagedFeedImage (CoreDataFeedStore file)
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
```
