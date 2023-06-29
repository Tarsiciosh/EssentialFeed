import XCTest
import EssentialFeed

extension FeedUIIntegrationTests {
    
    var loadError: String {
        LoadResourcePresenter<Any, DummyView>.loadError
    }
    
    var feedTitle: String {
        FeedPresenter.title
    }
    
    private class DummyView: ResourceView {
        func display(_ viewModel: Any) { }
    }
}
