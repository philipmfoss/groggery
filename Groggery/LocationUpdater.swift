
//  Copyright © 2017 GoGo Bits. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationUpdaterDelegate: class {
    
    func locationUpdaterDidNotVerifyLocationServicesEnabled(_ updater: LocationUpdater)
}

class LocationUpdater : NSObject, CLLocationManagerDelegate {
    
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate                           = self
        manager.desiredAccuracy                    = kCLLocationAccuracyKilometer
        manager.pausesLocationUpdatesAutomatically = true
        return manager
    }()
    
    weak var delegate: LocationUpdaterDelegate?
    
    private(set) var started = false
    
    @objc private(set) dynamic var currentLocation: CLLocation?

    func updateLocation() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            fallthrough
        case .authorizedAlways:
            verifyLocationServicesEnabled()
        default:
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    private func verifyLocationServicesEnabled() {
        if !CLLocationManager.locationServicesEnabled() {
            delegate?.locationUpdaterDidNotVerifyLocationServicesEnabled(self)
        }
        else {
            start()
        }
    }
    
    private func start() {
        guard !started else {
            return
        }
        
        locationManager.startUpdatingLocation()
        started = true
    }

    private func stop() {
        guard started else {
            return
        }
        
        locationManager.stopUpdatingLocation()
        started = false
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count > 0 {
            currentLocation = locations.first
        }
        stop()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            fallthrough
        case .authorizedWhenInUse:
            verifyLocationServicesEnabled()
        default:
            break
        }
    }
}
