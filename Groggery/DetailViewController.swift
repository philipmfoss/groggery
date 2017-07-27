
//  Copyright © 2017 GoGo Bits. All rights reserved.
//

import UIKit
import YelpAPI
import SDWebImage
import MBProgressHUD
import StarRatingView

class DetailViewController: UIViewController {

    @IBOutlet weak var heroImageView:          UIImageView!
    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var nameLabel:              UILabel!
    @IBOutlet weak var ratingView:             UIView!
    @IBOutlet weak var reviewsCountLabel:      UILabel!
    @IBOutlet weak var latestReviewLabel:      UILabel!
    @IBOutlet weak var addressLabel:           UILabel!
    @IBOutlet weak var provinceLabel:          UILabel!
   
    var client:   YLPClient?
    
    private(set) var latestReview: YLPReview?

    func configureView() {
        
        guard self.isViewLoaded, let restaurant = restaurant else {
            return
        }

        MBProgressHUD.showAdded(to: self.heroImageView, animated: true)
        self.heroImageView.sd_setImage(with: restaurant.imageURL) { (image, error, type, url) in
            MBProgressHUD.hide(for: self.heroImageView, animated: true)
            if let image = image {
                self.heroImageView.alpha = 1
                self.heroImageView.image = image
            }
            else {
                self.heroImageView.alpha = 0.1
                self.heroImageView.image = UIImage(named: "groggery")
            }
            
            self.view.setNeedsLayout()
        }
        
        nameLabel.text         = restaurant.name
        
        let conf = StarRatingViewConfiguration()
        conf.rateEnabled = true
        conf.starWidth   = 40
        conf.fullImage   = "full_star.png"
        conf.halfImage   = "half_star.png"
        conf.emptyImage  = "empty_star.png"
        if let starRatingView = StarRatingView(frame: CGRect(x:0,y:0,width:ratingView.frame.width,height:ratingView.frame.height), configuration: conf) {
            ratingView.addSubview(starRatingView)
            starRatingView.rating = CGFloat(restaurant.rating)
        }
        
        reviewsCountLabel.text = NSLocalizedString("Based on \(restaurant.reviewCount) reviews", comment: "")
        addressLabel.text      = restaurant.location.address.first
        latestReviewLabel.numberOfLines = -1

        loadLatestReview(success: { (review) in
            DispatchQueue.main.async {
                if let review = review {
                    self.latestReviewLabel.text = NSLocalizedString("\"\(review.excerpt)\"", comment: "")
                }
                else {
                    self.latestReviewLabel.text = nil
                }
            }
        }) { (error) in
            DispatchQueue.main.async {
                self.latestReviewLabel.text = nil
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var restaurant: YLPBusiness? {
        didSet {
            configureView()
        }
    }
    
    private func loadLatestReview(success: @escaping((YLPReview?)->()), failure: @escaping((Error?)->())) {
        guard let client = client, let restaurant = restaurant else {
            return
        }
        
        client.reviewsForBusiness(withId: restaurant.identifier) { (reviews, error) in
            if let reviews = reviews {
                let sortedReviews = reviews.reviews.sorted(by: { (a, b) -> Bool in
                    return a.timeCreated > b.timeCreated
                })
                if sortedReviews.count > 0 {
                    let latestReview = sortedReviews.first
                    success(latestReview)
                    return
                }
                
            }
            failure(error)
        }
    }
}

