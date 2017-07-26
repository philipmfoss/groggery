
//  Copyright © 2017 GoGo Bits. All rights reserved.
//

import Foundation
import YelpAPI

extension YLPClient {
    
    // Maximum number of restaurants to be returned by search.
    static let maxRestaurants = UInt(10)
    
    // Gets the clientId and secret from the Yelp object in ifo.plist and authorizes a YLPClient
    // No arguments
    // Passes back YLPCLient object on success
    static func authorize(success: @escaping((YLPClient)->()), failure: @escaping((Error?)->())) {

        guard let yelpDictionary = Bundle.main.object(forInfoDictionaryKey: "Yelp") as? [String:Any], let clientId = yelpDictionary["clientId"] as? String, let secret = yelpDictionary["secret"] as? String else {
            failure(nil)
            return
        }

        YLPClient.authorize(withAppId: clientId, secret: secret) { (client, error) in
            if let client = client {
                success(client)
            }
            else {
                failure(error)
            }
        }
    }
    
    // Searches for the top 10 restaurants based on search term and location
    // Takes the search term and the location as a latitude and longitude
    // Passes back an array of YLPBusiness objects on success
    func searchForRestaurants(term: String, latitude: Double, longitude: Double, success: @escaping(([YLPBusiness])->()), failure: @escaping((Error?)->())) {
        
        let coordinates = YLPCoordinate(latitude: latitude, longitude: longitude)
        let query = YLPQuery(coordinate: coordinates)
        query.categoryFilter = ["restaurants"]
        query.limit          = YLPClient.maxRestaurants
        query.term           = term
        self.search(with: query, completionHandler: { (search, error) in
            if let error = error {
                failure(error)
            }
            else {
                if let businesses = search?.businesses {
                    print(businesses)
                    
                    let businesses = businesses.sorted(by: { (a, b) -> Bool in
                        return a.name < b.name
                    })
                    
                    success(businesses)
                }
            }
        })
    }
}

