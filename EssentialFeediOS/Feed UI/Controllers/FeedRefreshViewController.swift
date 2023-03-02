import UIKit

public class FeedRefreshViewController: NSObject, FeedLoadingView {
    private(set) lazy var view = loadView()
    
    private let feedPresenter: FeedPresenter

    init(feedPresenter: FeedPresenter) {
        self.feedPresenter = feedPresenter
    }
    
    @objc func refresh() {
        feedPresenter.loadFeed()
    }
    
    func display(_ viewModel: FeedLoadingViewModel) {
        if viewModel.isLoading {
            view.beginRefreshing()
        } else {
            view.endRefreshing()
        }
    }
    
    private func loadView() -> UIRefreshControl {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }
}
