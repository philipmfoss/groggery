
//  Copyright © 2017 GoGo Bits. All rights reserved.
//

import UIKit
import CoreData
import YelpAPI
import SDWebImage
import MBProgressHUD
import CRToast

class MasterViewController: UICollectionViewController, UISearchBarDelegate {

    var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil
    
    private(set) var client: YLPClient?
    private(set) var restaurants = [YLPBusiness]()
    private(set) var searchTerm  = ""
    
    var resultsString: String? {
        if self.client != nil {
            if self.searchTerm == "" {
                if self.restaurants.count > 1 {
                    return NSLocalizedString("Showing all restaurants.", comment: "")
                }
                else {
                    return NSLocalizedString("No restaurants found.", comment: "")
                }
            }
            else {
                if self.restaurants.count > 1 {
                    return NSLocalizedString("Restaurants matching \"\(self.searchTerm)\"", comment: "")
                }
                else {
                    return NSLocalizedString("No restaurants found for search \"\(self.searchTerm)\"", comment: "")
                }
            }
        }
        else {
            return NSLocalizedString("Signing in...", comment: "")
        }
    }

    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addSearch()
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }

        signIn()
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        self.searchController.searchBar.isHidden = false
        super.viewWillAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        self.searchController.searchBar.isHidden = true
        super.viewDidDisappear(animated)
    }

    // MARK: - Collection View
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            if let headerView = self.collectionView?.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ResultsReusableView", for: indexPath) as? RestaurantsCollectionSupplementaryView {
                headerView.resultsLabel.text = resultsString
                return headerView
            }
        }
        
        return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return restaurants.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? YelpBusinessCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        if indexPath.row < restaurants.count {
            let business = self.restaurants[indexPath.row]
            configureCell(cell, withBusiness: business)
        }

        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowBusinessDetail" {
            guard let detailNavController = segue.destination as? UINavigationController, let detailViewController = detailNavController.topViewController as? DetailViewController, let indexPath = self.collectionView?.indexPathsForSelectedItems?.first else {
                return
            }
            
            detailViewController.client   = self.client
            detailViewController.business = self.restaurants[indexPath.row]
        }
    }
    private func configureCell(_ cell: YelpBusinessCollectionViewCell, withBusiness business: YLPBusiness) {        
        cell.business = business
    }
    
    private func signin(success: @escaping(()->()), failure:@escaping((Error?)->())) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        YLPClient.authorize(success: { (client) in
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.client = client
                success()
            }
        }) { (error) in
            guard let error = error else {
                return
            }
            print("Error searching app \(error)")
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                failure(error)
            }
        }
    }

    private func refresh(success: @escaping(()->()), failure:@escaping((Error?)->())) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        self.client?.searchForRestaurants(term: "", latitude: 43.7, longitude: -79.4, success: { (businesses) in
            self.restaurants = businesses
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                success()
            }
        }, failure: { (error) in
            guard let error = error else {
                return
            }
            print("Error searching app \(error)")
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                failure(error)
            }
        })
    }
    
    private func addSearch() {
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate                   = self
        searchController.searchBar.searchBarStyle             = .minimal
        searchController.searchBar.tintColor                  = UIColor.white
        searchController.searchBar.barTintColor               = UIColor.white
        self.navigationController?.navigationBar.addSubview(searchController.searchBar)
        
        for subview in searchController.searchBar.subviews {
            for field in subview.subviews {
                if let textField = field as? UITextField {
                    textField.textColor = UIColor.white
                    break
                }
            }
        }
    }
    
    // MARK: - Search Results
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        guard let term = searchBar.text else {
            return
        }

        searchTerm = term
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        self.client?.searchForRestaurants(term: term, latitude: 43.7, longitude: -79.4, success: { (businesses) in
            self.restaurants = businesses
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.searchController.searchBar.text = nil
                self.collectionView?.reloadData()
                self.collectionView?.contentOffset = CGPoint.zero
            }
        }, failure: { (error) in
            DispatchQueue.main.async {
                guard let error = error else {
                    return
                }
                print("Error searching app \(error)")
                MBProgressHUD.hide(for: self.view, animated: true)
                CRToast.toast(message: NSLocalizedString("Error searching. Please try again.", comment: ""), completion: {})
            }
        })
    }
    
    private func signIn() {
        
        signin(success: {
            self.refresh(success: {
                self.collectionView?.reloadData()
            }, failure: { (error) in
                CRToast.toast(message: NSLocalizedString("Error getting restaurants.", comment: ""), completion: {})
                self.collectionView?.reloadData()
            })
        }, failure: { (error) in
            let alert = UIAlertController(title: "Oops", message: "Error Signing in.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: { (action) in
                self.signIn()
            }))
            self.present(alert, animated: true, completion: nil)
        })
    }
}
