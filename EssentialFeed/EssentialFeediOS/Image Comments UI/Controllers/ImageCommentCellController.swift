import UIKit
import EssentialFeed

public class ImageCommentCellController: CellController {
    var model: ImageCommentViewModel
    
    public init(model: ImageCommentViewModel) {
        self.model = model
    }
    
    public func view(in tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell() as ImageCommentCell
        cell.massageLabel.text = model.message
        cell.usernameLabel.text = model.username
        cell.dateLabel.text = model.date
        return cell
    }
    
    public func preload() {}
    
    public func cancelLoad() {}
}
