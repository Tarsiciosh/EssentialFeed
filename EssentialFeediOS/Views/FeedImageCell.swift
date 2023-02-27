import UIKit

public final class FeedImageCell: UITableViewCell {
    public var locationContainer = UIView()
    public var descriptionLabel = UILabel()
    public var locationLabel = UILabel()
    public var feedImageContainer = UIView()
    public let feedImageView = UIImageView()
    private(set) public lazy var feedImageRetryButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action:  #selector(retryButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    var onRetry: (() -> Void)?
    
    @objc func retryButtonTapped() {
        onRetry?()
    }
}

