/*
 * Copyright 2016 MasterCard International.
 *
 * Redistribution and use in source and binary forms, with or without modification, are
 * permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this list of
 * conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 * conditions and the following disclaimer in the documentation and/or other materials
 * provided with the distribution.
 * Neither the name of the MasterCard International Incorporated nor the names of its
 * contributors may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */
import UIKit
import Moya
import CoreLocation

let CellIdentifier = "Cell"

let images = [#imageLiteral(resourceName: "Vending-1"), #imageLiteral(resourceName: "Vending-2"), #imageLiteral(resourceName: "Vending-3"), #imageLiteral(resourceName: "Vending-4")]

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var loadingView: UIView!
    @IBOutlet weak var nearestFilterButton: UIButton!
    
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation?
    
    var nearbyMachines = [Machine]()
    
    var nearbyMachineRequest: Cancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = NSLocalizedString("AnyDrink", comment: "")
        
        self.locationManager = CLLocationManager()
        locationManager.delegate = self
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "settings"), style: .plain, target: self, action: #selector(showSettings))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refresh))
        self.refresh()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        self.nearbyMachineRequest?.cancel()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if "machineDetail" == segue.identifier,
            let vc = segue.destination as? MachineViewController,
            let indexPath = self.tableView.indexPathForSelectedRow {
            
            vc.machine = self.nearbyMachines[indexPath.row]
        }
    }
    
    // MARK:- Private methods
    func showSettings() {
        self.performSegue(withIdentifier: "settings", sender: self)
    }
    
    func refresh() {
        showLoadingView()
        
        if Settings.sharedInstance.useMobileLocation {
            locationManager.requestLocation()
        } else {
            locationManager(locationManager, didUpdateLocations: [Settings.sharedInstance.stubbedLocation])
        }
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
            self.hideLoadingView()
            switch result {
            case let .success(response):
                do {
                    print(response)
                    self.nearbyMachines = try response.mapArray(type: Machine.self)
                } catch {
                    self.showAlert(title: "Nearby machines", message: "Unable to fetch from server")
                }
                self.tableView.reloadData()
            case let .failure(error):
                switch error {
                case .underlying(let nsError):
                    self.showAlert(title: "Nearby machines", message: nsError.localizedDescription)
                    break
                default:
                    guard let error = error as? CustomStringConvertible else {
                        return
                    }
                    self.showAlert(title: "Nearby machines", message: error.description)
                }
            }
        }
    }
    
    func showAlert(title: String, message: String) {
        let vc = UIAlertController(title: title, message: message, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            
        present(vc, animated: true, completion: nil)
    }
    
    func showLoadingView() {
        nearestFilterButton.isEnabled = false
        
        self.view.addSubview(loadingView)
        
        self.loadingView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addConstraint(NSLayoutConstraint.init(item: loadingView, attribute: .top, relatedBy: .equal, toItem: tableView, attribute: .top, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint.init(item: loadingView, attribute: .left, relatedBy: .equal, toItem: tableView, attribute: .left, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint.init(item: loadingView, attribute: .bottom, relatedBy: .equal, toItem: tableView, attribute: .bottom, multiplier: 1.0, constant: 0))
        self.view.addConstraint(NSLayoutConstraint.init(item: loadingView, attribute: .right, relatedBy: .equal, toItem: tableView, attribute: .right, multiplier: 1.0, constant: 0))
        
        self.view.layoutIfNeeded()
        
        self.loadingView.alpha = 0.0
        UIView.animate(withDuration: 0.2) {
            self.loadingView.alpha = 1.0
        }
    }
    
    func hideLoadingView() {
        nearestFilterButton.isEnabled = true
        self.loadingView.removeFromSuperview()
        
        self.loadingView.alpha = 1.0
        UIView.animate(withDuration: 0.2) {
            self.loadingView.alpha = 0.0
        }
    }
}

// MARK: - Table view methods
extension ViewController : UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nearbyMachines.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier) as? VendingCell else {
            return UITableViewCell()
        }
        
        let machine = nearbyMachines[indexPath.row]
        cell.configureCell(machine: machine, image: images[indexPath.row % images.count])
        
        return cell
    }
}

extension ViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Core location methods
extension ViewController : CLLocationManagerDelegate {
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

// MARK: - Cell
class VendingCell : UITableViewCell {
    @IBOutlet weak var machineImageView: UIImageView!
    @IBOutlet weak var machineNameLabel: UILabel!
    @IBOutlet weak var machineDistanceLabel: UILabel!
    @IBOutlet weak var machineAddressLabel: UILabel!
    
    func configureCell(machine: Machine, image: UIImage) {
        machineNameLabel.text = machine.name
        machineDistanceLabel.text = machine.formatDistance()
        machineAddressLabel.text = machine.address
        
        machineImageView.image = image
    }
}

private class HeaderView : UITableViewHeaderFooterView {
    let machinesCountLabel: UILabel = UILabel()
    let detailLabel: UILabel = UILabel()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.backgroundColor = UIColor.white
        
        machinesCountLabel.translatesAutoresizingMaskIntoConstraints = false
        machinesCountLabel.font = UIFont.systemFont(ofSize: 14)
        machinesCountLabel.textColor = UIColor.textGray
        
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.textColor = UIColor.squash
        
        self.contentView.addSubview(machinesCountLabel)
        self.contentView.addSubview(detailLabel)
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        let viewsDict = ["machinesCountLabel": machinesCountLabel, "detailLabel": detailLabel]
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[machinesCountLabel]-[detailLabel]-|", options: [.alignAllCenterY, .alignAllTop, .alignAllBottom], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[machinesCountLabel]-|", options: [], metrics: nil, views: viewsDict))
        
        detailLabel.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
    }
    
    func configureCell(machinesCount: Int) {
        machinesCountLabel.text = "\(machinesCount) vending machines"
        detailLabel.text = "Nearest"
    }
}
