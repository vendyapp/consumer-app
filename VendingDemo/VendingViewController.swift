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

protocol VendingFlow : class {
    func flowComplete()
    func showReceipt(machineName: String, quantity: Int, amount: String, cardMaskedPan: String)
}

enum ButtonState : Int {
    case PairingFailed = 1
}

class VendingViewController : UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var pageControl: PageControl!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var countdownView: UIView!
    @IBOutlet weak var countdownLabel: UILabel!
    
    weak var delegate: VendingFlow?
    
    let settings = Settings.sharedInstance
    
    var vendController: VendController!
    var machine: Machine!
    var countdownTimer: Timer?
    var countdownTime = 20
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pageControl.numberOfPages = 4
        connect()
        
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.squash.cgColor
        layer.fillColor = nil;
        self.button.layer.addSublayer(layer)
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: self.button.bounds.width, y: 0))
        layer.path = path.cgPath
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        cancelCountdown()
    }
    
    // MARK: - Private methods
    func connect() {
        self.pageControl.isHidden = false
        self.button.isHidden = true
        self.countdownView.isHidden = true
        
        if let resultType = settings.resultType {
            print("Using fake bluetooth")
            vendController = VendController(config: resultType)
        } else {
            print("Using bluetooth dongle")
            vendController = VendController(deviceModel: machine.model, deviceSerial: machine.serial, serviceId: machine.serviceId, maxAmount: Amount(amount: 1.0))
        }
        
        vendController.delegate = self
        do {
            try vendController.connect()
            self.imageView.image = #imageLiteral(resourceName: "Pairing")
            self.pageControl.currentPage = 0
            self.textLabel.text = NSLocalizedString("Pairing with the vending machine...", comment: "")
        } catch {
            print(error)
        }
        
        self.countdownTime = 30
    }
    
    func cancelCountdown() {
        self.countdownTimer?.invalidate()
        self.countdownTimer = nil
        
        self.countdownView.isHidden = true
    }
    
    func countdownTick() {
        self.countdownTime -= 1
        if self.countdownTime <= 0 {
            self.vendController.disconnect()
            cancelCountdown()
            showError(error: "Timeout!")
        }
        
        self.countdownLabel.text = "\(countdownTime)"
    }
    
    func showError(error: String) {
        self.pageControl.isHidden = true
        self.button.isHidden = false
        
        self.imageView.image = #imageLiteral(resourceName: "PairingFailed")
        self.textLabel.text = NSLocalizedString(error, comment: "")
        self.button.setTitle(NSLocalizedString("Pair Again", comment: ""), for: .normal)
        self.button.tag = ButtonState.PairingFailed.rawValue
    }
    
    // MARK: - Action methods
    @IBAction func buttonPressed(_ sender: UIButton) {
        guard let buttonState = ButtonState.init(rawValue: sender.tag) else {
            print("Invalid button state")
            return
        }
        if buttonState == ButtonState.PairingFailed {
            connect()
        }
    }
}

extension VendingViewController : VendControllerDelegate {
    func connected() {
        print("Connected")
        self.imageView.image = #imageLiteral(resourceName: "MakeSelection")
        self.pageControl.currentPage = 1
        self.textLabel.text = NSLocalizedString("Pick the item you want in vending machine by pressing its number", comment: "")
        self.countdownLabel.text = "\(countdownTime)"
        
        self.countdownView.isHidden = false
        countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(countdownTick), userInfo: nil, repeats: true)
    }
    
    func disconnected(_ error: VendError) {
        print("Connection disconnected: \(error)")
        
        cancelCountdown()
        
        switch error {
        case .connectionTimedOut:
            showError(error: "Timeout!")
        case .invalidDeviceResponse:
            // TODO: Show different UI
            fallthrough
        case .bluetoothNotAvailable:
            // TODO: Show different UI
            fallthrough
        default:
            showError(error: NSLocalizedString("Pairing failed", comment: ""))
        }
        
        self.vendController.delegate = nil
        self.vendController = nil
    }
    
    func authRequest(_ amount: NSNumber, token: String?) {
        print("Auth requested")
        
        cancelCountdown()
        
        self.imageView.image = #imageLiteral(resourceName: "Authorizing")
        self.pageControl.currentPage = 2
        self.textLabel.text = NSLocalizedString("Authorizing your payment Info...", comment: "")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) { [weak self] in
            self?.vendController.approveAuth("dummyPayload")
            
            self?.imageView.image = #imageLiteral(resourceName: "Approving")
            self?.pageControl.currentPage = 3
            self?.textLabel.text = NSLocalizedString("Placing the payment...\n\n$ \(amount)", comment: "")
        }
    }
    
    func processStarted() {
        print("Process started")
    }
    
    func processCompleted(_ finalAmount: NSNumber, processStatus: ProcessStatus, completedPayload: String) {
        print("Process completed")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
            if processStatus == .success {
                // Show receipt
                let amount = String(format: "%0.2f", finalAmount.floatValue)
                self?.delegate?.showReceipt(machineName: self?.machine.name ?? "", quantity: 1, amount: "USD \(amount)", cardMaskedPan: "**** 4567")
                
                self?.delegate?.flowComplete()
            } else {
                self?.showError(error: "Vending failed")
            }
        }
    }
    
    func invalidProduct() {
        print("Invalid product requested")
    }
    
    func timeoutWarning() {
        print("Timeout warning")
        
        self.vendController.keepAlive()
    }
}

// MARK: Custom page control
class PageControl : UIView {
    var numberOfPages: Int = 1 {
        didSet {
            configureView()
        }
    }
    
    var currentPage: Int = 0 {
        didSet {
            configureView()
        }
    }
    
    // MARK: - Private methods
    override func layoutSubviews() {
        configureView()
    }
    
    func configureView() {
        self.backgroundColor = UIColor.squash.withAlphaComponent(0.3)
        self.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let width = self.bounds.width / CGFloat(numberOfPages)
        let lineWidth = CGFloat(2.0)
        
        // Select current page
        for i in 0..<numberOfPages {
            guard i <= currentPage else {
                continue
            }
            
            let layer = CAShapeLayer()
            layer.fillColor = UIColor.squash.cgColor
            self.layer.addSublayer(layer)
            
            let x = width * CGFloat(i)
            let path = UIBezierPath(rect: CGRect(x: x, y: 0, width: width, height: self.bounds.height))
            layer.path = path.cgPath 
        }
        
        // Draw borders of pages
        for i in 1..<numberOfPages {
            let layer = CAShapeLayer()
            layer.lineWidth = lineWidth
            layer.strokeColor = UIColor.backgroundGray.cgColor
            layer.fillColor = nil;
            self.layer.addSublayer(layer)
            
            let x = width * CGFloat(i)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: self.bounds.height))
            layer.path = path.cgPath
        }
    }
}
