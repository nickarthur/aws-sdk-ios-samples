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

import Foundation
import AWSCore

struct Constants {
    // nan debug
    static let uuid =
        "NANIoTSampleApp-" + UUID().uuidString; // generate our own clientId
    // nan debug

    //WARNING: To run this sample correctly, you must set the following constants.
    static let AWSRegion = AWSRegionType.USEast1 // e.g. AWSRegionType.USEast1
    static let CognitoIdentityPoolId = "us-east-1:01ef5d41-4d42-42b7-ab54-8bc9823db4e3"
    static let CertificateSigningRequestCommonName = "AWS IoT Certificate"
    static let CertificateSigningRequestCountryName = "US"
    static let CertificateSigningRequestOrganizationName = "Amazon.com Inc."
    static let CertificateSigningRequestOrganizationalUnitName = "Amazon Web Services"
    static let PolicyName = "NANIoTSampleAppIoTPolicy"

    //let AWSRegion = AWSRegionType.Unknown // e.g. AWSRegionType.USEast1
    //let CognitoIdentityPoolId = "YourCognitoIdentityPoolId"
    //let CertificateSigningRequestCommonName = "IoTSampleSwift Application"
    //let CertificateSigningRequestCountryName = "Your Country"
    //let CertificateSigningRequestOrganizationName = "Your Organization"
    //let CertificateSigningRequestOrganizationalUnitName = "Your Organizational Unit"
    //let PolicyName = "YourPolicyName"

    // This is the endpoint in your AWS IoT console. eg: https://xxxxxxxxxx.iot.<region>.amazonaws.com

    static let IOT_ENDPOINT = "https://a2045eufe4r87o-ats.iot.us-east-1.amazonaws.com"
    static let ASWIoTDataManager = "MyIotDataManager"

    //let IOT_ENDPOINT = "https://xxxxxxxxxx.iot.<region>.amazonaws.com"
    //let ASWIoTDataManager = "MyIotDataManager"
    
}
