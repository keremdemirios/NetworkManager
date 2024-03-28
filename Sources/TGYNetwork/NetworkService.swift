//
//  File.swift
//  
//
//  Created by Kerim Çağlar on 26.03.2024.
//

import UIKit

public struct NetworkService {
    public static let shared = NetworkService()
    private init() {}
}

public struct ServiceError: Codable {
    var errorKey: String?
    var message: String?
    var status: String?
    var path: String?
}

public enum NetworkError: Error {
    
    public enum ErrorMessageConstant {
        static let defaultErrorMessage = "Geçici bir sorun oluştu"
        static let defaultConnectionErrorMessage = "Internet bağlantısı yok"
    }
    
    case operationFailed
    case connectionError
    case serviceError(ServiceError)
    case error(Error)
    
    public var message: String? {
        switch self {
        case .operationFailed:
            return ErrorMessageConstant.defaultErrorMessage
        case .connectionError:
            return ErrorMessageConstant.defaultConnectionErrorMessage
        case .serviceError(let serviceError):
            return serviceError.message
        case .error(let error):
            return error.localizedDescription
        }
    }
}

extension NetworkError {
    static func showAlert(with error: NetworkError) {
        let message = error.message ?? ErrorMessageConstant.defaultErrorMessage
        
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        guard let controller = UIApplication.shared.windows.first?.rootViewController else { return }
        controller.present(alert, animated: true)
    }
}
