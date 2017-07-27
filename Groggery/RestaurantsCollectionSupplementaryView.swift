
//  Copyright © 2017 GoGo Bits. All rights reserved.
//

import UIKit

protocol RestaurantsCollectionSupplementaryViewDelegate: class {
    func restaurantsCollectionSupplementaryView(_ view: RestaurantsCollectionSupplementaryView, didChangeSortOrderTo sortOrder: SortOrder)
}

enum SortOrder {
    case up
    case down
}

class RestaurantsCollectionSupplementaryView : UICollectionReusableView {
    
    @IBOutlet var resultsLabel:   UILabel!
    @IBOutlet var sortUpButton:   UIButton!
    @IBOutlet var sortDownButton: UIButton!
    
    weak var delegate: RestaurantsCollectionSupplementaryViewDelegate?
    
    var sortOrder: SortOrder = .up {
        didSet {
            self.sortUpButton.isHidden   = sortOrder == .down
            self.sortDownButton.isHidden = sortOrder == .up
        }
    }
    
    @IBAction func sort(sender: UIButton) {
        if sender == sortUpButton {
            sortOrder = .down
        }
        else if sender == sortDownButton {
            sortOrder = .up
        }
        delegate?.restaurantsCollectionSupplementaryView(self, didChangeSortOrderTo: sortOrder)
    }
    
}
