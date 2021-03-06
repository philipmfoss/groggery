
//  Copyright © 2017 GoGo Bits. All rights reserved.
//

import Foundation
import YelpAPI

protocol GroggeryDelegate: class {
    func groggeryDidUpdateLocation(_ groggery: GroggeryClient)
}

enum GroggeryState {
    case signedOut
    case signingIn
    case signedIn
    case loading
}

class GroggeryClient: NSObject, LocationUpdaterDelegate {
    
    var locationObserverContext: UnsafeMutableRawPointer?
    var sortOrder: SortOrder = .up {
        didSet {
            switch sortOrder {
            case .up:
                UserDefaults.standard.set(0, forKey: "GroggerySortOrder")
            case .down:
                UserDefaults.standard.set(1, forKey: "GroggerySortOrder")
            }
            self.sort()
        }
    }

    weak var locationDelegate: LocationUpdaterDelegate?
    weak var delegate:         GroggeryDelegate?
    
    private(set) var client:               YLPClient?
    private(set) var searchTerm:           String?
    private(set) var restaurants = [YLPBusiness]()
    
    private var state: GroggeryState = .signedOut
    
    private(set) lazy var updater: LocationUpdater = {
        var updater = LocationUpdater()
        updater.addObserver(self, forKeyPath: #keyPath(LocationUpdater.currentLocation), options: [.new, .old], context: &self.locationObserverContext)
        return updater
    }()
    
    
    override init() {
        let sortOrderSetting = UserDefaults.standard.integer(forKey: "GroggerySortOrder")
        switch sortOrderSetting {
        case 1:
            sortOrder = .down
        default:
            sortOrder = .up
        }
        super.init()
    }
    
    func signIn(success: @escaping(()->()), failure:@escaping((Error?)->())) {
        updater.updateLocation()
        authorize(success: success, failure: failure)
    }
    
    func search(term: String?, success: @escaping(()->()), failure:@escaping((Error?)->())) {
        guard let location = updater.currentLocation, state == .signedIn else {
            failure(nil)
            return
        }
        
        state = .loading

        searchTerm = term
        
        self.client?.searchForRestaurants(term: term, latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, success: { (businesses) in
            self.state = .signedIn
            self.restaurants = businesses
            self.sort()
            success()
        }, failure: { (error) in
            guard let error = error else {
                return
            }
            print("Error searching app \(error)")
            self.state = .signedIn
            failure(error)
        })
    }
    
    func loadLatestReviewForRestaurant(restaurant: YLPBusiness?, success: @escaping((YLPReview?)->()), failure: @escaping((Error?)->())) {
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
    
    // MARK: - Internal
    private func authorize(success: @escaping(()->()), failure:@escaping((Error?)->())) {
        guard state == .signedOut else {
            return
        }
        
        state = .signingIn
        
        YLPClient.authorize(success: { (client) in
            DispatchQueue.main.async {
                self.client = client
                self.state = .signedIn
                success()
            }
        }) { (error) in
            guard let error = error else {
                return
            }
            print("Error searching app \(error)")
            DispatchQueue.main.async {
                self.state = .signedOut
                failure(error)
            }
        }
    }
    
    private func sort() {
        switch sortOrder {
        case .up:
            self.restaurants = self.restaurants.sorted(by: { (a, b) -> Bool in
                return a.name < b.name
            })
        case .down:
            self.restaurants = self.restaurants.sorted(by: { (a, b) -> Bool in
                return a.name > b.name
            })
        }
    }
    
    // MARK: - Overrides
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "currentLocation" {
            search(term: self.searchTerm, success: {
                self.delegate?.groggeryDidUpdateLocation(self)
            }, failure: { (error) in })
        }
    }
    
    // MARK: - LocationUpdaterDelegate
    func locationUpdaterDidNotVerifyLocationServicesEnabled(_ updater: LocationUpdater) {
        locationDelegate?.locationUpdaterDidNotVerifyLocationServicesEnabled(updater)
    }
}
