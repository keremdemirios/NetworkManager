//
//  BaseRequest.swift
//
//
//  Created by Kerim Çağlar on 26.03.2024.
//

import Foundation
import Alamofire

protocol BaseRequestProtocol: AnyObject {
    
    var host: String { get } //https://www.turkcell.com.tr
    var route: String { get }
    var httpMethod: HTTPMethod { get }
    var headers: HTTPHeaders { get }
    var timeOut: TimeInterval { get }
    var showAlertWhenError: Bool { get }
    var isMultiPart: Bool { get }
    
}

open class BaseRequest: BaseRequestProtocol {
    
    public init() {}
    
    open var host: String {
        return ""
    }
    
    open var route: String {
        return ""
    }
    
    open var httpMethod: HTTPMethod {
        .get
    }
    
    open var headers: HTTPHeaders {
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "accept", value: "application/json")
        headers.add(name: "deviceType", value: "iOS")
        return headers
    }
    
    open var timeOut: TimeInterval {
        return 20
    }
    
    open var showAlertWhenError: Bool {
        return true
    }
    
    open var isMultiPart: Bool {
        return false
    }
    
    open var urlString: String {
        host + route
    }
    
}
