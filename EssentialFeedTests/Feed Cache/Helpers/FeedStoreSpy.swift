import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
    enum ReceivedMessage: Equatable {
        case deleteCacheFeed
        case insert([LocalFeedImage], Date)
    }
    
    private(set) var receiveMessages = [ReceivedMessage]()
    
    private var deletionsCompletions = [DeletionCompletion]()
    private var insertionsCompletions = [InsertionCompletion]()
    
    func deleteCacheFeed(completion: @escaping DeletionCompletion) {
        deletionsCompletions.append(completion)
        receiveMessages.append(.deleteCacheFeed)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionsCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionsCompletions[index](nil)
    }
    
    func insert (_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping (Error?) -> Void) {
        insertionsCompletions.append(completion)
        receiveMessages.append(.insert(feed, timestamp))
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionsCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionsCompletions[index](nil)
    }
}
