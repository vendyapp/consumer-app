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
import VendingSDK
import CoreLocation

let settingsKey = "settings"
let useBluetoothSimulatorKey = "useBluetoothSimulator"

class Settings : NSObject {
    static let sharedInstance: Settings = Settings()
    
    var useStubbedMachines: Bool {
        get { return UserDefaults.standard.bool(forKey: "useStubbedMachines") }
        set { UserDefaults.standard.set(newValue, forKey: "useStubbedMachines") }
    }
    
    dynamic var useBluetoothSimulator: Bool = true
    var resultType: ControllerResultConfig? {
        get {
            if let resultTypeString = UserDefaults.standard.object(forKey: "resultType") as? String,
                let resultType = ControllerResultConfig(from: resultTypeString) {
                return resultType
            }
            
            return nil
        }
        set {
            UserDefaults.standard.set(newValue?.toString(), forKey: "resultType")
            if newValue == nil {
                useBluetoothSimulator = true
            } else {
                useBluetoothSimulator = false
            }
        }
    }
    
    var useMobileLocation: Bool {
        get { return UserDefaults.standard.bool(forKey: "useMobileLocation") }
        set { UserDefaults.standard.set(newValue, forKey: "useMobileLocation") }
    }
    
    var hotelLocation : CLLocation {
        if let locationString = Bundle.main.object(forInfoDictionaryKey: "StubbedLocation") as? String {
            let components = locationString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if components.count == 2, let latitude = Double(components[0]), let longitude = Double(components[1]) {
                return CLLocation(latitude: latitude, longitude: longitude)
            }
        }
        
        return CLLocation(latitude: 0, longitude: 0)
    }
    
    var stubbedLocation: CLLocation {
        get {
            let latitude = UserDefaults.standard.double(forKey: "latitude")
            let longitude = UserDefaults.standard.double(forKey: "longitude")
            return CLLocation(latitude: latitude, longitude: longitude)
        }
        set {
            UserDefaults.standard.set(newValue.coordinate.latitude, forKey: "latitude")
            UserDefaults.standard.set(newValue.coordinate.longitude, forKey: "longitude")
        }
    }
    
    var serverUrl: URL {
        get {
            if let urlString = UserDefaults.standard.object(forKey: "serverUrl") as? String, let url = URL(string: urlString) {
                return url
            } else {
                return URL(string: Bundle.main.object(forInfoDictionaryKey: "VendingServerURL") as! String)!
            }
        }
        set { UserDefaults.standard.set(newValue.absoluteString, forKey: "serverUrl") }
    }
    
    private override init() {
        super.init()
        
        if !UserDefaults.standard.bool(forKey: "firstTime") {
            useStubbedMachines = false
            resultType = .allSuccess
            useMobileLocation = true
            stubbedLocation = hotelLocation
            
            UserDefaults.standard.set(true, forKey: "firstTime")
        }
        
        useBluetoothSimulator = resultType == nil
    }
}

class SettingsViewController: UIViewController {
    let resultTypes : [ControllerResultConfig] = [.allSuccess, .deviceNotLocated, .connectionFailed, .vendingFailed]
    
    let settings: Settings = Settings.sharedInstance
    
    @IBOutlet weak var stubbedMachinesSwitch: UISwitch!
    @IBOutlet weak var bluetoothSimulatorSwitch: UISwitch!
    @IBOutlet weak var serverUrlTextField: UITextField!
    @IBOutlet weak var resultTypeTextField: UITextField!
    @IBOutlet weak var mobileLocationSwitch: UISwitch!
    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        serverUrlTextField.delegate = self
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 50))
        toolBar.barStyle = UIBarStyle.default
        toolBar.items = [
            UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(hideKeyboard))]
        toolBar.sizeToFit()
        
        resultTypeTextField.inputAccessoryView = toolBar
        resultTypeTextField.inputView = pickerView
        
        latitudeTextField.inputAccessoryView = toolBar
        longitudeTextField.inputAccessoryView = toolBar
        
        bluetoothSimulatorSwitch.isOn = settings.useBluetoothSimulator
        stubbedMachinesSwitch.isOn = settings.useStubbedMachines
        serverUrlTextField.text = settings.serverUrl.absoluteString
        serverUrlTextField.isEnabled = !settings.useStubbedMachines
        mobileLocationSwitch.isOn = settings.useMobileLocation
        enableMobileLocation(flag: settings.useMobileLocation)
        
        settings.addObserver(self, forKeyPath: useBluetoothSimulatorKey, options: [.initial, .new], context: nil)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSettings))
    }
    
    deinit {
        settings.removeObserver(self, forKeyPath: useBluetoothSimulatorKey)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == useBluetoothSimulatorKey else {
            return
        }
        
        if settings.useBluetoothSimulator {
            resultTypeTextField.text = "Using bluetooth dongle"
            resultTypeTextField.isEnabled = false
            
            if let pickerView = resultTypeTextField.inputView as? UIPickerView {
                pickerView.selectRow(0, inComponent: 0, animated: false)
            }
        } else {
            resultTypeTextField.text = settings.resultType?.description
            resultTypeTextField.isEnabled = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Action methods
    @IBAction func stubbedMachinesSwitched(_ sender: UISwitch) {
        settings.useStubbedMachines = sender.isOn
        serverUrlTextField.isEnabled = !settings.useStubbedMachines
    }
    
    @IBAction func bluetoothSimulatorSwitched(_ sender: UISwitch) {
        if sender.isOn {
            settings.resultType = nil
        } else {
            settings.resultType = .allSuccess
        }
    }
    
    @IBAction func mobileLocationSwitched(_ sender: UISwitch) {
        enableMobileLocation(flag: sender.isOn)
    }
    
    // MARK: - Private methods
    func enableMobileLocation(flag: Bool) {
        settings.useMobileLocation = flag
        
        latitudeTextField.text = "\(Settings.sharedInstance.stubbedLocation.coordinate.latitude)"
        latitudeTextField.isEnabled = !flag
        
        longitudeTextField.text = "\(Settings.sharedInstance.stubbedLocation.coordinate.longitude)"
        longitudeTextField.isEnabled = !flag
    }
    func dismissSettings() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    func showError(message: String) {
        let alert = UIAlertController(title: "Error!", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension SettingsViewController : UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let result = resultTypes[row]
        
        settings.resultType = result
    }
}

extension SettingsViewController : UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return resultTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return resultTypes[row].description
    }
}

extension SettingsViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case serverUrlTextField:
            textField.resignFirstResponder()
            return true
        default:
            if textField.text == nil {
                return false
            }
            textField.resignFirstResponder()
            return true
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case serverUrlTextField:
            if let text = textField.text, let url = URL(string: text) {
                settings.serverUrl = url
            } else {
                showError(message: "Invalid url")
            }
        case latitudeTextField:
            guard let text = textField.text, let latitude = Double(text) else {
                latitudeTextField.text = "\(Settings.sharedInstance.stubbedLocation.coordinate.latitude)"
                showError(message: "Invalid latitude")
                return
            }
            
            let stubbedLocation = Settings.sharedInstance.stubbedLocation.coordinate
            let location = CLLocation(latitude: latitude, longitude: stubbedLocation.longitude)
            Settings.sharedInstance.stubbedLocation = location
        case longitudeTextField:
            guard let text = textField.text, let longitude = Double(text) else {
                longitudeTextField.text = "\(Settings.sharedInstance.stubbedLocation.coordinate.latitude)"
                showError(message: "Invalid longitude")
                return
            }
            
            let stubbedLocation = Settings.sharedInstance.stubbedLocation.coordinate
            let location = CLLocation(latitude: stubbedLocation.latitude, longitude: longitude)
            Settings.sharedInstance.stubbedLocation = location
        default:
            break
        }
    }
}
