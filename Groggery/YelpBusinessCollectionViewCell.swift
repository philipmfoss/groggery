
//  Copyright © 2017 GoGo Bits. All rights reserved.
//

import UIKit

import MBProgressHUD
import YelpAPI

class YelpBusinessCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView:    UIImageView!
    @IBOutlet var nameLabel:    UILabel!
    @IBOutlet var addressLabel: UILabel!
    
    private var hud: MBProgressHUD?
    
    var business: YLPBusiness? {
        didSet {
            guard let business = self.business else {
                self.imageView.image   = nil
                self.nameLabel.text    = nil
                self.addressLabel.text = nil
                return
            }
            self.nameLabel.text    = business.name
            if let address = business.location.address.first {
                self.addressLabel.text = address
            }
            else if business.location.city.characters.count > 0 {
                self.addressLabel.text = business.location.city
            }
            else {
                self.addressLabel.text = nil
            }

            MBProgressHUD.showAdded(to: self.imageView, animated: true)
            self.imageView.sd_setImage(with: business.imageURL) { (image, error, type, url) in
                MBProgressHUD.hide(for: self.imageView, animated: true)
                if let image = image {
                    self.imageView.alpha = 1
                    self.imageView.image = image
                }
                else {
                    self.imageView.alpha = 0.1
                    self.imageView.image = UIImage(named: "groggery")
                }
            }
        }
    }
    
    override func prepareForReuse() {
        MBProgressHUD.hide(for: self.imageView, animated: false)
        business = nil
        imageView.alpha = 1
    }
}
