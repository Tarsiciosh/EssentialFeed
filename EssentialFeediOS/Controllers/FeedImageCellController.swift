import UIKit
import EssentialFeed

final public class FeedImageCellController {
    private var model: FeedImage
    private var imageLoader: FeedImageDataLoader
    private var task: FeedImageDataLoaderTask?
    
    init(model: FeedImage, imageLoader: FeedImageDataLoader) {
        self.imageLoader = imageLoader
        self.model = model
    }
    
    func view() -> UITableViewCell {
        let cell = FeedImageCell()
        cell.descriptionLabel.text = model.description
        cell.locationContainer.isHidden = (model.location == nil)
        cell.locationLabel.text = model.location
        cell.feedImageContainer.startShimmering()
        cell.feedImageView.image = nil
        cell.feedImageRetryButton.isHidden = true
        
        let loadImage = { [weak self, weak cell] in
            guard let self = self else { return }
            
            self.task = self.imageLoader.loadImageData(from: self.model.url) { [weak cell] result in
                let data = try? result.get()
                let image = data.map(UIImage.init) ?? nil
                cell?.feedImageView.image = image
                cell?.feedImageRetryButton.isHidden = (image != nil)
                cell?.feedImageContainer.stopShimmering()
            }
        }
        
        cell.onRetry = loadImage
        loadImage()
        
        return cell
    }
    
    func preload() {
        task = imageLoader.loadImageData(from: model.url) { _ in }
    }
    
    func cancelLoad() {
        task?.cancel()
    }
}

