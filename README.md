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
[remove mutable state from `FeedViewModel`. The `FeedViewModel` only needs to forward state changes, so state in only transient]
- add a FeedImageViewModel (repeat the steps)
- add imageTransformer (closure recieving Data and returning generic typy optional Image)
- add imageTransformer closure injection to the init method
- fix the view model - fix the composer - fix the controller
[decouple `FeedImageViewModel` from `UIKit` by creating a transformation closure that converts an image `Data` value into a generic `Image` type. When composing wiht a UIKit user interface, we inject a closure to transform the image `Data` into `UIImage`]
- remove EssentialFeed import from the FeedViewController (no longer needed)
[remove `EssentialFeed` module import from `FeedViewController` file since it does not depend on any `EssentialFeed` component]
```
