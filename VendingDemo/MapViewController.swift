//
//  MapViewController.swift
//  VendingDemo
//
//  Created by Felipe Valdez on 10/22/16.
//  Copyright © 2016 Muhammad Azeem. All rights reserved.
//

import UIKit
import Moya
import Foundation
import CoreLocation
import MapKit

class MapViewController : UIViewController {
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation?
    
    var nearbyMachines = [Machine]()
    var nearbyMachineRequest: Cancellable?
    
    @IBOutlet var loadingView: UIView!
    @IBOutlet var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = NSLocalizedString("MasterKey", comment: "")
        
        self.locationManager = CLLocationManager()
        locationManager.delegate = self
    }
    
    func fetchNearbyMachines(force: Bool = false) {
        guard let currentLocation = currentLocation else {
            return
        }
        
        if let request = nearbyMachineRequest, request.cancelled {
            if force {
                request.cancel()
            } else {
                return
            }
        }
        
        let latitude = Float(currentLocation.coordinate.latitude)
        let longitude = Float(currentLocation.coordinate.longitude)
        
        nearbyMachineRequest = UnattendedRetailProvider.request(.nearbyMachines(latitude: Float(latitude), longitude: Float(longitude))) { [unowned self] result in
            //self.hideLoadingView()
            switch result {
            case let .success(response):
                do {
                    print(response)
                    self.nearbyMachines = try response.mapArray(type: Machine.self)
                } catch {
                    //self.showAlert(title: "Nearby machines", message: "Unable to fetch from server")
                }
                //self.tableView.reloadData()
            case let .failure(error):
                switch error {
                case .underlying(let nsError):
                    //self.showAlert(title: "Nearby machines", message: nsError.localizedDescription)
                    break
                default:
                    guard let error = error as? CustomStringConvertible else {
                        return
                    }
                    //self.showAlert(title: "Nearby machines", message: error.description)
                }
            }
        }
    }
    
    func showLoadingView() {
        
        self.view.addSubview(loadingView)
        
        self.view.layoutIfNeeded()
        
        self.loadingView.alpha = 0.0
        UIView.animate(withDuration: 0.2) {
            self.loadingView.alpha = 1.0
        }
    }
    
    func hideLoadingView() {
        self.loadingView.removeFromSuperview()
        
        self.loadingView.alpha = 1.0
        UIView.animate(withDuration: 0.2) {
            self.loadingView.alpha = 0.0
        }
    }
    
    func showAlert(title: String, message: String) {
        let vc = UIAlertController(title: title, message: message, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        present(vc, animated: true, completion: nil)
    }
    
    func refresh() {
        showLoadingView()
        
        if Settings.sharedInstance.useMobileLocation {
            locationManager.requestLocation()
        } else {
            locationManager(locationManager, didUpdateLocations: [Settings.sharedInstance.stubbedLocation])
        }
    }
}

// MARK: - Core location methods
extension MapViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            refresh()
        case .denied, .restricted:
            let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName")
            showAlert(title: "Location Error!", message: "Location permission is required to find nearby machines. Go to 'Settings -> \(appName) -> Location' and select 'While Using the App'")
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        
        currentLocation = location
        fetchNearbyMachines()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Swift.Error) {
        print("Location manager failed with error: \(error)")
        showAlert(title: "Location Error!", message: "Cannot determine your location. Please try again.")
        hideLoadingView()
    }
}

extension MapViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // do something
    }
}
