# Vending SDK for iOS
[Mastercard Vending]

## Requirements
1. Xcode 8.0
2. iOS 9.0+ running device.

## Steps to run example project:
1. Install cocoapods
2. Do `pod install`
3. Change the bundle identifier to your own bundle identifier
4. Enable development signing in the project settings and sign with your identities to be able to run on a device.
5. Build and run.

## Steps to import VendingSDK into your project:
### Swift
- Download the latest release of [VendingSDK] you can also find the SDK in the example project by the name `VendingSDK.framework`.
- Go to your Xcode project’s “General” settings. Drag VendingSDK.framework to the “Embedded Binaries” section. Make sure Copy items if needed is selected and click Finish.
- Create a new “Run Script Phase” in your app’s target’s “Build Phases” and paste the following snippet in the script text field:

    `bash "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/VendingSDK.framework/strip-frameworks.sh"`
    
  This step is required to work around an App Store submission bug when archiving universal binaries.

### Objc
- Follow same instructions as Swift
- Go to your Xcode project's "Build Settings" and set "Always Embed Swift Standard Libraries" to "YES"

## Usage
1. Import VendingSDK in your controller
2. Create instance of `VendController` using the initializer `init(deviceModel:String, deviceSerial: String, serviceId: String, maxAmount: Amount)`
3. Implement `VendControllerDelegate`
4. Set your controller to be the delegate of `VendController`
5. You are good to go

#### The flow is as following:
1. After the above steps, call `connect` function on VendController to start the connection.
2. `connected` will be called on the delegate if the connection is successful else `disconnected` will be called with the error.
3. Now you can implement your own timer logic or you can rely on the device's timer where `timeoutWarning` will be called every time the timeout is about to happen. You can extend the time by calling `keepAlive` on the controller
4. Now you should make selection on the vending machine or you can call `selectProduct` with a product id to select a product on the machine.
5. `authRequest` will be called on the delegate for requesting authorization of the amount and you should authorize the requested amount with the vending server.
6. After authorization, you should call `approveAuth` with the approval payload or you can call `disapprove` to disapprove the authorization request.
7. `processCompleted` will be called at the end with process status such as `success, fail or cancel` based on the status in the machine.
8. If the status was success then item will have been vended.

## Docs

#### Following functions are exposed in `VendController`
1. Initializer `init(deviceModel:String, deviceSerial: String, serviceId: String, maxAmount: Amount)`. 
    * parameter deviceModel: Model string of the target device
    * parameter deviceSerial: Serial string of the target device
    * parameter serviceId: Service id of the target device.
    * parameter maxAmount: Maximum amount to allow for vending. Vending machine maximum amount limit will be used if the provided amount is greater than what the machine can allow.
2. Connect to the device `func connect()`. The device is searched first and if the device is found according to the parameters provided in `init` method then a connection is established. Throws `VendError.alreadyConnected` exception if the connection is already in progress.
3. Disconnect from the device `func disconnect()`. You should wait for `disconnected` delegate method before attempting to connect again.
4. Approve auth `func approveAuth(_ authApprovalPayload: String)`.
    * parameter authApprovalPayload: Auth approval payload that will be verified on the device to approve the authorization of the amount requested
5. Disapprove auth request `func disapprove()`
6. Keep connection alive `func keepAlive()`. This must be called to keep the connection alive after specific intervals because the connection is short-lived.
7. Select product on the device `func selectProduct(productId: String)`.
    * paramter productId: Id of the product to select. This can result in `invalidProduct` delegate method to be called if the provided product id is not valid.

#### Following are the functions that are included in `VendControllerDelegate`
1. Device connected. `func connected()`
2. Device disconnected. `func disconnected(_ error: VendError)`
    * parameters error: Error that caused the disconnected
3. Auth is requested. `func authRequest(_ amount: NSNumber, token: String?)`
    * parameter amount: Amount to authorize
    * parameter token: Token for authorization containing the payload. It will be sent to the server for authorization.
4. Process started. `func processStarted()`
5. Process completed. `func processCompleted(_ finalAmount: NSNumber, processStatus: ProcessStatus, completedPayload: String)`
    * parameter finalAmount: Amount used for the process
    * parameter processStatus: Status of the process
    * parameter completedPayload: Payload. It will be used to mark the process for completion on the server
6. Invalid product requested. `func invalidProduct()`
7. Timeout warning. `func timeoutWarning()`
     - Note: You should send `keepAlive` commands in this method to keep the connection alive

#### Errors for `disconnected` function
1. `bluetoothNotAvailable` occurs if the bluetooth is unavailable
2. `unsupportedSoftwareRevision` occurs if the software revision of the device is not supported
3. `deviceNotLocated` occurs if the device could not be located
4. `invalidDeviceId` occurs if the device was found properly but it had invalid device id
5. `connectionTimedOut` occurs if an established connection is timed out
6. `invalidDeviceResponse` occurs if the device responded unexpectedly
7. `alreadyConnected` occurs if the device is already connected to us
8. `unexpectedDisconnection` occurs if the connection was abruptly closed

### Testing
For testing purposes `VendController` also exposes a separate initializer `init(config: ControllerResultConfig)`. This initializer will start the `VendController` in stub mode. You can use it if you don't want to interact with bluetooth simulator. You still need to test it on an actual device.
Each value in `ControllerResultConfig` represents what you want to expect from the controller. So for example if you want to stub a complete vending success flow then you can pass `allSuccess` and if you want to expect an error during vending then you can pass `vendingFailed`.

#### ControllerResultConfig is an enum with following values:
1. `allSuccess`. Everything is successful
2. `deviceNotLocated`. Device could not be located while scanning
3. `connectionFailed`. Device could not be connected
4. `vendingFailed` Vending failed

**This is already done in the settings screen**. You can access the screen by tapping on the left bar button. Here you can specify if you want to use bluetooth simulator and if not then what response you are expecting.

[Vending SDK]: <https://developer.mastercard.com/media/e1/7f/dbdda8b240be816229cf16bffacbVendingSDK.framework.zip>
[Mastercard Vending]: <https://developer.mastercard.com/product/mastercard-vending>