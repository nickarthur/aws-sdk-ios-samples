/*
* Copyright 2010-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

import UIKit
import AWSIoT
import SwiftyJSON

//
// These values must match the values from the temperature-control example
// in the aws-iot-device-sdk.js package (https://github.com/aws/aws-iot-device-sdk-js)
//
let statusThingName="TemperatureStatus"
let controlThingName="TemperatureControl"

class ViewController: UIViewController {
    @IBOutlet weak var setpointLabel: UILabel!
    @IBOutlet weak var interiorLabel: UILabel!
    @IBOutlet weak var exteriorLabel: UILabel!
    @IBOutlet weak var statusSwitch: UISwitch!
    @IBOutlet weak var setpointStepper: UIStepper!

    var interiorTemperature: Int = 70;
    var exteriorTemperature: Int = 45;
    var currentRunningState: String="stopped";
    var currentlyEnabled: Bool = true;
    var currentSetpoint: Int = 68;
    var currentSetpointStepValue: Double!;
    var statusThingOperationInProgress:  Bool = false;
    var controlThingOperationInProgress: Bool = false; // initially not doing anything
    weak var setupTimer: Timer?;

    var iotDataManager: AWSIoTDataManager!;
    
    
    
    
    @IBAction func statusSwitchChanged(_ sender: UISwitch) {
        //
        // Initialize the control JSON object
        //
        let controlJson = JSON(
            ["state": ["desired": [ "setPoint": currentSetpoint, "enabled": sender.isOn]]])

        if (!controlThingOperationInProgress)
        {
            // step 1: remember the switch position
            currentlyEnabled = sender.isOn;
            
            // step 2: update the swith seting in the iot cloud device shadow
            self.iotDataManager.updateShadow( controlThingName, jsonString: controlJson.rawString()! )
            
            // step 3: switch change until we complete the operation
            controlThingOperationInProgress = true
        }
        else
        {
            // return the switch to previous value
            sender.isOn = currentlyEnabled;    // cancel the operation
        }
    }
    
    
    
    
    @IBAction func setpointStepperTapped(_ sender: UIStepper) {
        //
        // Initialize the control JSON object
        //
        let controlJson = JSON([
            "state": [
                "desired":
                [
                    "setPoint": Int(sender.value),
                    "enabled": currentlyEnabled
                ]
            ]
            ])

        if (!controlThingOperationInProgress)
        {
            // step 1: read and remember the stepper value
            self.currentSetpoint = Int(setpointStepper.value) // remember the setpoint
            
            // step 2: Update the UI Label
            setpointLabel.text = String(currentSetpoint) // update the UI
            
            // step 3: write device shadow to the iot cloud
            self.iotDataManager.updateShadow( controlThingName, jsonString: controlJson.rawString()! )
            
            // prevent another operation until this one completes
            controlThingOperationInProgress = true
        }
        else
        {
            // return the stepper to the previos value
            // because we're not done with the previous operation
            sender.value = currentSetpointStepValue;    // cancel the operation
        }
    }

    
    
    func updateStatus( _ interiorTemperature: Int?, exteriorTemperature: Int?, state: String? )
    {
        if let interiorTemperature = interiorTemperature {
            interiorLabel.text = String(interiorTemperature)
        }
        if let exteriorTemperature = exteriorTemperature {
            exteriorLabel.text = String(exteriorTemperature)
        }
        if let state = state {
            currentRunningState = state
            switch(currentRunningState)
            {
            case "stopped":
                interiorLabel.textColor = UIColor(red:0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            case "heating":
                interiorLabel.textColor = UIColor(red:1.0, green: 0.0, blue: 0.0, alpha: 1.0)
            case "cooling":
                interiorLabel.textColor = UIColor(red:0.0, green: 0.0, blue: 1.0, alpha: 1.0)
            default:
                interiorLabel.textColor = UIColor(red:0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            }
        }
    }
    
    
    
    func updateControl( _ setPoint: Int?, enabled: Bool? )
    {
        if let setPoint = setPoint {
            setpointStepper.value=Double(setPoint)
            setpointLabel.text = String(setPoint)
            currentSetpointStepValue = setpointStepper.value;
            currentSetpoint = Int(currentSetpointStepValue);
        }
        if let enabled = enabled {
            statusSwitch.isOn = enabled
            currentlyEnabled = enabled;
        }
    }
    
    
    
    func thingShadowTimeoutCallback( _ thingName: String, json: JSON, payloadString: String ) -> Void {
        
        // signal that the operation completed
        // so the user can make additional temp. adjustments
        if (thingName == controlThingName)
        {
            controlThingOperationInProgress = false;
        }
        else   // thingName == statusThingName
        {
            statusThingOperationInProgress = false;
        }
    }
    
    
    
    func thingShadowDeltaCallback( _ thingName: String, json: JSON, payloadString: String ) -> Void {
        if (thingName == controlThingName)
        {
            updateControl( json["state"]["setPoint"].int,
                enabled: json["state"]["enabled"].bool );
        }
        else   // thingName == statusThingName
        {
            updateStatus( json["state"]["intTemp"].int,
                exteriorTemperature: json["state"]["extTemp"].int,
                state: json["state"]["curState"].string );
        }
    }
    
    
    
    func thingShadowAcceptedCallback( _ thingName: String, json: JSON, payloadString: String ) -> Void {
        
        if (thingName == controlThingName)
        {
            // parse json for setpoint and enabled status and pass
            // the values to updateControl
            updateControl( json["state"]["desired"]["setPoint"].int,
                enabled: json["state"]["desired"]["enabled"].bool );
            
            // let user send more control signals
            controlThingOperationInProgress = false;
        }
        else   // thingName == statusThingName
        {
            // parse json for the statusThing's info and pass to
            // UpdateStatus method
            updateStatus( json["state"]["desired"]["intTemp"].int,
                exteriorTemperature: json["state"]["desired"]["extTemp"].int,
                state: json["state"]["desired"]["curState"].string );
            statusThingOperationInProgress = false;
        }
    }
    
    
    
    func thingShadowRejectedCallback( _ thingName: String, json: JSON, payloadString: String ) -> Void {
        
        if (thingName == controlThingName)
        {
            // free the ui to make more changes
            controlThingOperationInProgress = false;
        }
        else   // thingName == statusThingName
        {
            statusThingOperationInProgress = false;
        }
        print("operation rejected on: \(thingName)")
    }
    
    
    
    func getThingStates() {
        self.iotDataManager.getShadow(statusThingName)
        self.iotDataManager.getShadow(controlThingName)
    }
  
    
    
   
    func deviceShadowCallback(name:String, operation:AWSIoTShadowOperationType, operationStatus:AWSIoTShadowOperationStatusType, clientToken:String, payload:Data){
        
        DispatchQueue.main.async {
            guard let json = try? JSON(data: (payload as NSData!) as Data) else {
                print("Could not get JSON")
                
                return
            }
            let stringValue = NSString(data: payload, encoding: String.Encoding.utf8.rawValue)
            
            switch(operationStatus) {
                
            case .accepted:
                print("accepted on \(name)")
                self.thingShadowAcceptedCallback( name, json: json, payloadString: stringValue! as String)
                
            case .rejected:
                print("rejected on \(name)")
                self.thingShadowRejectedCallback( name, json: json, payloadString: stringValue! as String)
                
            case .delta:
                print("delta on \(name)")
                self.thingShadowDeltaCallback( name, json: json, payloadString: stringValue! as String)
                
            case .timeout:
                print("timeout on \(name)")
                self.thingShadowTimeoutCallback( name, json: json, payloadString: stringValue! as String)
                
            default:
                print("unknown operation status: \(operationStatus.rawValue)")
            }
        }
    }
    
    
    
    func mqttEventCallback( _ status: AWSIoTMQTTStatus )
    {
        DispatchQueue.main.async {
            print("connection status = \(status.rawValue)")
            switch(status)
            {
            case .connecting:
                print( "Connecting..." )
                
            case .connected:
                print( "Connected" )
                //
                // Register the device shadows once connected.
                //
                self.iotDataManager.register(withShadow: statusThingName, options:nil,  eventCallback: self.deviceShadowCallback)
                
                self.iotDataManager.register(withShadow: controlThingName, options:nil, eventCallback: self.deviceShadowCallback )
                
                //
                // Two seconds after registering the device shadows, retrieve their current states.
                //
                Timer.scheduledTimer( timeInterval: 2.5, target: self, selector: #selector(ViewController.getThingStates), userInfo: nil, repeats: false )
                
            case .disconnected:
                print( "Disconnected" )
                
            case .connectionRefused:
                print( "Connection Refused" )
                
            case .connectionError:
                print( "Connection Error" )
                
            case .protocolError:
                print( "Protocol Error" )
                
            default:
                print("unknown state: \(status.rawValue)")
            }
        }
    }


    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        //
        // Initialize the setpoint stepper
        //
        setpointStepper.wraps=false
        
        // set temperature limits
        setpointStepper.maximumValue=90
        setpointStepper.minimumValue=50
        // initially set to a cozy 70 deg
        setpointStepper.value=70
        
        // remember the current temp.
        currentSetpointStepValue = setpointStepper.value
        //
        // Initialize the temperature and setpoint labels
        //
        interiorLabel.text="60"
        exteriorLabel.text="45"
        setpointLabel.text=setpointStepper.value.description
        //
        // Initialize the status switch
        //
        statusSwitch.isOn=true

        //
        // Use Cognito authentication
        //
        let credentialProvider = AWSCognitoCredentialsProvider(regionType: AwsRegion, identityPoolId: CognitoIdentityPoolId)
        
        let iotEndPoint = AWSEndpoint(urlString: IOT_ENDPOINT)
        
        let iotDataConfiguration = AWSServiceConfiguration(
            region: AwsRegion,
            endpoint: iotEndPoint,
            credentialsProvider: credentialProvider)

        //
        // Init IOT
        //

        AWSIoTDataManager.register(with: iotDataConfiguration!, forKey: "MyIotDataManager")
        iotDataManager = AWSIoTDataManager(forKey: "MyIotDataManager")


        #if DEMONSTRATE_LAST_WILL_AND_TESTAMENT
        //
        // Set a Last Will and Testament message in the MQTT configuration; other
        // clients can subscribe to this topic, and if this client disconnects from
        // from AWS IoT unexpectedly, they will receive the message defined here.
        // Note that this is optional; your application may not need to specify a
        // Last Will and Testament.
        //
        // To enable this code, add '-DDEMONSTRATE_LAST_WILL_AND_TESTAMENT' to
        // your project build flags in:
        //
        //    Build Settings -> Swift Compiler - Custom Flags -> Other Swift Flags
        //
        // IMPORTANT NOTE FOR SWIFT PROGRAMS: When specifying the Last Will and Testament
        // message in Swift, make sure to use the NSString data type; this object must
        // support the dataUsingEncoding selector, which is not available in Swift's
        // native String type.
        //
        let lwtTopic: NSString = "temperature-control-last-will-and-testament"
        let lwtMessage: NSString = "disconnected"
        self.iotDataManager.mqttConfiguration.lastWillAndTestament.topic = lwtTopic as String
        self.iotDataManager.mqttConfiguration.lastWillAndTestament.message = lwtMessage as String
        self.iotDataManager.mqttConfiguration.lastWillAndTestament.qos = .messageDeliveryAttemptedAtMostOnce
        #endif

        //
        // Connect via WebSocket
        //
        self.iotDataManager.connectUsingWebSocket( withClientId: UUID().uuidString, cleanSession:true, statusCallback: mqttEventCallback)
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

