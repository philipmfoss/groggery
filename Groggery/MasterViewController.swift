
//  Copyright © 2017 GoGo Bits. All rights reserved.
//

import UIKit
import YelpAPI
import SDWebImage
import MBProgressHUD
import CRToast

class MasterViewController: UICollectionViewController, UISearchBarDelegate, LocationUpdaterDelegate, GroggeryDelegate, RestaurantsCollectionSupplementaryViewDelegate {

    var detailViewController: DetailViewController? = nil
    
    let searchController = UISearchController(searchResultsController: nil)
    
    private lazy var groggery: Groggery = {
        let groggery = Groggery()
        groggery.locationDelegate = self
        groggery.delegate         = self
        return groggery
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        self.addSearch()

        signIn(success: {
            self.groggery.search(term: nil, success: {
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                }
            }, failure: { (error) in
                DispatchQueue.main.async {
                    CRToast.toast(message: NSLocalizedString("Error getting restaurants.", comment: ""), completion: {})
                    self.collectionView?.reloadData()
                }
            })
        }) { (error) in
            MBProgressHUD.hide(for: self.view, animated: true)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        self.searchController.searchBar.isHidden = false
        super.viewWillAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = !splitViewController!.isCollapsed
        self.searchController.searchBar.isHidden = true
        super.viewDidDisappear(animated)
    }

    // MARK: - Collection View
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            if let headerView = self.collectionView?.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ResultsReusableView", for: indexPath) as? RestaurantsCollectionSupplementaryView {
                headerView.resultsLabel.text = groggery.resultsString
                headerView.delegate  = self
                headerView.sortOrder = self.groggery.sortOrder
                return headerView
            }
        }
        
        return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return groggery.restaurants.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? YelpBusinessCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        if indexPath.row < groggery.restaurants.count {
            let business = groggery.restaurants[indexPath.row]
            configureCell(cell, withBusiness: business)
        }

        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowBusinessDetail" {
            guard let indexPath = self.collectionView?.indexPathsForSelectedItems?.last else {
                return
            }
            
            let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
            controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
            controller.client     = self.groggery
            controller.restaurant = groggery.restaurants[indexPath.row]
        }
    }
    
    // MARK: - Internal
    private func signIn(success: @escaping(()->()), failure: @escaping((Error?)->())) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        groggery.signIn(success: {
            MBProgressHUD.hide(for: self.view, animated: true)
            success()
        }) { (error) in
            failure(error)
            let alert = UIAlertController(title: "Oops", message: "Error Signing in.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: { (action) in
                self.signIn(success: success, failure: failure)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func configureCell(_ cell: YelpBusinessCollectionViewCell, withBusiness business: YLPBusiness) {
        cell.business = business
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
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        groggery.search(term: searchBar.text, success: { 
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.searchController.searchBar.text = nil
                self.collectionView?.reloadData()
                self.collectionView?.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
                self.searchController.isActive = false
            }
        }) { (error) in
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                CRToast.toast(message: NSLocalizedString("Error searching. Please try again.", comment: ""), completion: {})
            }
        }        
    }
    
    // MARK: - LocationUpdaterDelegate
    func locationUpdaterDidNotVerifyLocationServicesEnabled(_ updater: LocationUpdater) {
        let alert = UIAlertController(title: "Location Settings", message: "This application requires Location settings to be enabled.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Go to Location settings.", style: .default, handler: { (action) in
            UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - GroggeryDelegate
    func groggeryDidUpdateLocation(_ groggery: Groggery) {
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }
    
    // MARK: - RestaurantsCollectionSupplementaryViewDelegate
    func restaurantsCollectionSupplementaryView(_ view: RestaurantsCollectionSupplementaryView, didChangeSortOrderTo sortOrder: SortOrder) {
        self.groggery.sortOrder = sortOrder
        self.collectionView?.reloadData()
    }
}
