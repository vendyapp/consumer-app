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
import Foundation
import Moya
import Alamofire
import UIKit

// MARK: - Provider setup

private func JSONResponseDataFormatter(_ data: Data) -> Data {
    do {
        let dataAsJSON = try JSONSerialization.jsonObject(with: data)
        let prettyData =  try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
        return prettyData
    } catch {
        return data //fallback to original data if it cant be serialized
    }
}

let stubClosure = { (target: UnattendedRetail) -> StubBehavior in
    if Settings.sharedInstance.useStubbedMachines {
        return StubBehavior.immediate
    }
    
    return StubBehavior.never
}

func manager() -> Manager {
    let configuration = URLSessionConfiguration.default
    configuration.httpAdditionalHeaders = Manager.defaultHTTPHeaders
    configuration.httpCookieStorage = HTTPCookieStorage.shared
    configuration.httpShouldSetCookies = false
    configuration.httpCookieAcceptPolicy = .always
    
    let manager = Manager(configuration: configuration)
    manager.startRequestsImmediately = false
    return manager
}

let UnattendedRetailProvider = MoyaProvider<UnattendedRetail>(stubClosure: stubClosure, manager: manager(), plugins: [NetworkLoggerPlugin(verbose: true, responseDataFormatter: JSONResponseDataFormatter)])

public func url(_ route: TargetType) -> String {
    return route.baseURL.appendingPathComponent(route.path).absoluteString
}

enum UnattendedRetail {
    case nearbyMachines(latitude: Float, longitude: Float)
}

extension UnattendedRetail: TargetType {
    public var baseURL: URL { return URL(string: Bundle.main.object(forInfoDictionaryKey: "VendingServerURL") as! String)! }
    public var path: String {
        switch self {
        case .nearbyMachines(_, _):
            return "/machines"
        }
    }
    public var method: Moya.Method {
        return .GET
    }
    public var parameters: [String: Any]? {
        switch self {
        case .nearbyMachines(let latitude, let longitude):
            return ["latitude": latitude, "longitude": longitude]
        }
    }
    public var task: Task {
        return .request
    }
    public var sampleData: Data {
        switch self {
        case .nearbyMachines(_, _):
            if let path = Bundle.main.path(forResource: "StubbedMachines", ofType: "json"),
                let data = NSData(contentsOfFile: path) as? Data {
                return data
            } else {
                return "{}".data(using: .utf8)!
            }
        }
    }
}
