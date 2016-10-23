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
import CoreLocation
import MapKit

class MachineInfoViewController : UIViewController {
    @IBOutlet weak var vendingTypeLabel: UILabel!
    @IBOutlet weak var machineDescriptionLabel: UILabel!
    @IBOutlet weak var machineDistanceLabel: UILabel!
    @IBOutlet weak var machineAddressLabel: UILabel!
    @IBOutlet weak var showOnMapButton: UIButton!
    @IBOutlet weak var pairButton: UIButton!
    
    var machine: Machine? {
        didSet {
            configureView()
        }
    }
    
    var pairCallback: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pairButtonPressed(self)
    }
    
    // MARK: - Action methods
    @IBAction func showOnMapButtonPressed(sender: UIButton) {
        guard let machine = machine else {
            return
        }
        
        let coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(machine.latitude), CLLocationDegrees(machine.longitude))
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
        mapItem.name = machine.name
        // TODO: Fix issue
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
    }
    
    @IBAction func pairButtonPressed(_ sender: AnyObject) {
        if let pairCallback = pairCallback {
            pairCallback()
        }
    }
    
    // MARK: - Private Methods
    func configureView() {
        guard let machine = self.machine else {
            self.vendingTypeLabel.text = "<INVALID DEVICE>"
            self.machineDescriptionLabel.text = "<INVALID DEVICE>"
            self.machineAddressLabel.text = "<INVALID DEVICE>"
            self.machineDistanceLabel.text = "<INVALID DEVICE>"
            
            self.showOnMapButton.isEnabled = false
            self.pairButton.isEnabled = false
            
            return
        }
        
        //self.vendingTypeLabel.text = machine.name
        //self.machineDescriptionLabel.text = "Michail's School Supplies"
        //self.machineAddressLabel.text = machine.address
        //self.machineDistanceLabel.text = machine.formatDistance()
        
        self.vendingTypeLabel.text = "Michail's School Supplies"
        self.machineDescriptionLabel.text = "Calculators, Books, and More"
        self.machineAddressLabel.text = ""
        self.machineDistanceLabel.text = ""

        
        self.showOnMapButton.isEnabled = true
        self.pairButton.isEnabled = true
    }
}
