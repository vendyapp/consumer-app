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
import Alamofire

class MachineViewController: UIViewController {
    @IBOutlet weak var machineNameLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var lblReceipt: UILabel!
    @IBOutlet weak var lblWarning: UILabel!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var machine: Machine?
    var currentVC: UIViewController?
    var vendController: VendController!

    override func viewDidLoad() {
        super.viewDidLoad()

        let logo = UIImage(named:"vendy_logo_2.png")
        let imageView = UIImageView(image:logo)
        self.navigationItem.titleView = imageView
        
        vendController = VendController(deviceModel: "1", deviceSerial:"1018",serviceId: "fff0", maxAmount: Amount(amount: 10.0))
        vendController = VendController(config:.allSuccess)

        vendController.delegate = self
        
        do {
            try vendController.connect()
        } catch {
            print(error)
        }

        // Do any additional setup after loading the view.
//        guard self.machine != nil else {
//            let vc = UIAlertController(title: "Error", message: "Machine information not available", preferredStyle: .alert)
//            vc.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { _ in
//                self.dismiss(animated: true, completion: nil)
//            }))
//            
//            present(vc, animated: true, completion: nil)
//            return
//        }
        
        //configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if "vending" == segue.identifier {
            let vc = segue.destination as! VendingViewController
            vc.machine = machine
        }
    }
    
    // MARK: - Private Methods
    func configureView() {
        
        //machineNameLabel.text = machine?.name
        
        containerView.subviews.forEach({ $0.removeFromSuperview() })
        
        currentVC = self.storyboard?.instantiateViewController(withIdentifier: "MachineInfoViewController")
        currentVC!.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(currentVC!)
        addSubview(subview: currentVC!.view, toView: containerView)

        let infoVC = currentVC as! MachineInfoViewController
        infoVC.machine = machine
        infoVC.pairCallback = {
            self.vendingFlow()
        }
    }

    func addSubview(subview: UIView, toView parentView: UIView) {
        parentView.addSubview(subview)
        
        var viewBindingsDict = [String: AnyObject]()
        viewBindingsDict["subview"] = subview
        parentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[subview]|",
                                                                 options: [], metrics: nil, views: viewBindingsDict))
        parentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[subview]|",
                                                                 options: [], metrics: nil, views: viewBindingsDict))
    }
    
    func cycleFromViewController(oldViewController: UIViewController, toViewController newViewController: UIViewController) {
        oldViewController.willMove(toParentViewController: nil)
        self.addChildViewController(newViewController)
        self.addSubview(subview: newViewController.view, toView:self.containerView!)
        newViewController.view.alpha = 0
        newViewController.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.5, animations: {
            newViewController.view.alpha = 1
            oldViewController.view.alpha = 0
            }, completion: { finished in
                oldViewController.view.removeFromSuperview()
                oldViewController.removeFromParentViewController()
                newViewController.didMove(toParentViewController: self)
        })
    }
    
    func reset() {
        let newViewController = self.storyboard?.instantiateViewController(withIdentifier: "MachineInfoViewController") as! MachineInfoViewController
        newViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.cycleFromViewController(oldViewController: self.currentVC!, toViewController: newViewController)
        self.currentVC = newViewController
        
        newViewController.pairCallback = {
            self.vendingFlow()
        }
    }
    
    func vendingFlow() {
        let newViewController = self.storyboard?.instantiateViewController(withIdentifier: "VendingViewController") as! VendingViewController
        newViewController.machine = machine
        newViewController.delegate = self
        newViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.cycleFromViewController(oldViewController: self.currentVC!, toViewController: newViewController)
        self.currentVC = newViewController
    }
    
    func makeVendyRequest() {
        Alamofire.request("http://104.155.107.44:5555/transfer")
            .responseJSON { (response:DataResponse<Any>) in
                print(response)
                self.vendController.approveAuth("dummyPayload")
        }
    }
}

// MARK: - VendingFlow methods
extension MachineViewController : VendingFlow {
    func flowComplete() {
        reset()
    }
    
    func showReceipt(machineName: String, quantity: Int, amount: String, cardMaskedPan: String) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "ReceiptViewController") as! ReceiptViewController
        vc.machineName = machineName
        vc.quantity = quantity
        vc.amount = amount
        vc.cardMaskedPan = cardMaskedPan
        
        let nav = UINavigationController(rootViewController: vc)
        self.navigationController?.present(nav, animated: true, completion: nil)
    }
}

extension MachineViewController : VendControllerDelegate {
    func connected() {
        print("Connected")
        self.activityIndicator.stopAnimating()
        self.lblMessage.text = "Select Item on Machine"
    }
    
    func disconnected(_ error: VendError) {
        self.activityIndicator.startAnimating()
        self.lblMessage.text = "Pairing Device..."
    }

    func authRequest(_ amount: NSNumber, token: String?) {
        print("Auth requested")
        self.activityIndicator.startAnimating()
        self.lblMessage.text = NSLocalizedString("Authorizing Payment...", comment: "")
        
        makeVendyRequest()
        //DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) { [weak self] in
        //    self?.vendController.approveAuth("dummyPayload")
            
        //}
    }
    
    func processStarted() {
        print("Process started")
    }
    
    func processCompleted(_ finalAmount: NSNumber, processStatus: ProcessStatus, completedPayload: String) {
        print("Process completed")
        self.activityIndicator.stopAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(0)) { [weak self] in
            if processStatus == .success {
                // Show receipt
                //let amount = String(format: "$%0.2f", finalAmount.floatValue)
                let amount = "$12.80"
                self?.lblReceipt.text = amount
                self?.lblMessage.text = "Collect Item from Machine"
                self?.lblWarning.text = "Payment Confirmed!"

                //self?.delegate?.flowComplete()
            } else {
                //self?.showError(error: "Vending failed")
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
