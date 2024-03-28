//
//  NetworkOperation.swift
//
//
//  Created by Kerim Çağlar on 26.03.2024.
//

import Foundation
import Alamofire

fileprivate enum NetworkConstants {
    static let unauthorizedCode = 401
}

public enum OperationState: String {
    case none
    case ready
    case finished
    case executing
}

protocol NetworkOperationProtocol: AnyObject {
    var operationState: OperationState { get set }
}

// didSet, willSet ne demektir ne işe yarar
// KVO ? Key Value Observing
class NetworkOperation<T, M>: Operation, NetworkOperationProtocol where T: Decodable, M: Codable {
    
    public var operationState: OperationState = .none {
        willSet {
            willChangeValue(forKey: newValue.rawValue)
        }
        
        didSet {
            didChangeValue(forKey: operationState.rawValue)
        }
    }
    
    open lazy var session: Session = {
        let configuration = URLSessionConfiguration.af.default
        let session = Session(configuration: configuration)
        return session
    }()
    
    /*open lazy var multiPartSession: Session = {
        let configuration = URLSessionConfiguration.af.default
        let session = Session(configuration: configuration)
        return session
    }()*/
    
    open var request: BaseRequest
    open var requestModel: M?
    
    open var completion: ((Result<T, Error>) -> Void)?
    
    open lazy var jsonDecoder: JSONDecoder = {
        let decoder: JSONDecoder = JSONDecoder()
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }()
    
    public init(request: BaseRequest,
                requestModel: M?,
                completion: ((Result<T, Error>) -> Void)? = nil
    ){
        self.request = request
        self.requestModel = requestModel
        self.completion = completion
    }
    
    open override func start() {
        if (NetworkReachabilityManager.default?.isReachable ?? true) == false {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if self.request.showAlertWhenError {
                    NetworkError.showAlert(with: .connectionError)
                }
                self.completion?(Result.failure(NetworkError.connectionError))
                self.operationState = .finished
            }
        } else if !isExecuting{
            operationState = .executing
            //performRequest()
        }
    }
    
    override var isReady: Bool {
        operationState == .ready
    }
    
    override var isExecuting: Bool {
        operationState == .executing
    }
    
    override var isFinished: Bool {
        operationState == .finished
    }
    
    override var isAsynchronous: Bool {
        return true
    }
}

extension NetworkOperation {
    
    public func performRequest() {
        print("******** performing request to: \(request.urlString) **********")
        print("******** request params: \(String(describing: requestModel)) *******")
        
        let req: DataRequest! = performDataRequest()
        
        //Http status kodları
        let emptyResponseCodes: Set<Int> = [201, 204, 205]
        
        let serializer = DataResponseSerializer(dataPreprocessor: DataResponseSerializer.defaultDataPreprocessor, emptyResponseCodes: emptyResponseCodes)
        
        req.response(queue: DispatchQueue.main, responseSerializer: serializer) { [weak self] response in
            guard let self else { return }
            self.handleResponse(response: response)
        }
    }
    
    public func performDataRequest() -> DataRequest {
        
        let req = session.request(request.urlString,
                                  method: request.httpMethod,
                                  parameters: requestModel,
                                  encoder: JSONParameterEncoder.default,
                                  headers: request.headers,
                                  requestModifier: nil)
        
        return req
    }
    
    public func handleResponse(response: DataResponse<Data, AFError>) {
        print("***** Status code: \(String(describing: response.response?.statusCode)), error: \(String(describing: response.error?.errorDescription))")
        
        switch response.response?.statusCode ?? 500 {
        case 200..<299: //Success code range
            self.handleResponse(data: response.data)
        default: //Network or Service Error
            let errorStr = createErrorMessage(response: response)
            self.handleError(data: response.data, error: response.error, code: response.response?.statusCode ?? 500, errorMessage: errorStr)
        }
    }
    
    public func createErrorMessage(response: DataResponse<Data, AFError>) -> String {
        let str = ""
        
        return str
    }
    
    public func handleResponse(data: Data?) {
        
        if let data {
            print("****** Success Result: \(String(decoding: data, as: UTF8.self)) *******")
            
            do {
                let decodableObject = try jsonDecoder.decode(T.self, from: data)
                completion?(Result.success(decodableObject))
                operationState = .finished
            } catch {
                let err = AFError.responseSerializationFailed(reason: .decodingFailed(error: error))
                print("********* JSON DECODE ERROR: \(err.localizedDescription) ********")
                completion?(Result.failure(err))
                operationState = .finished
            }
        } else {
            print("******* EMPTY Success Result *******")
            completion?(Result.success(BaseResponse() as! T))
            operationState = .finished
        }
    }
    
    public func handleError(data: Data?, error: AFError?, code: Int, errorMessage: String) {
        
        if let data {
            print("******* Custom Error response: \(String(decoding: data, as: UTF8.self)) ********")
            
            do {
                let decodedObject = try jsonDecoder.decode(ServiceError.self, from: data)
                let serviceError = NetworkError.serviceError(decodedObject)
                
                if self.request.showAlertWhenError {
                    if code >= 500 {
                        NetworkError.showAlert(with: .operationFailed)
                    } else {
                        NetworkError.showAlert(with: serviceError)
                    }
                    
                    completion?(Result.failure(serviceError))
                    operationState = .finished
                }
            } catch {
                let err = AFError.responseSerializationFailed(reason: .decodingFailed(error: error))
                print("******** JSON DECODE ERROR: \(err.localizedDescription) *********")
                completion?(Result.failure(err))
                operationState = .finished
            }
        } else {
            print("************* Error: \(String(describing: error)) ********")
            if request.showAlertWhenError {
                NetworkError.showAlert(with: .operationFailed)
            }
            
            completion?(Result.failure(NetworkError.operationFailed))
            operationState = .finished
        }
        
    }
}
