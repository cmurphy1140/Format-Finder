import Foundation
import SwiftUI

// MARK: - Error Types
enum AppError: LocalizedError {
    case dataDecodingFailed
    case bookmarkCorrupted
    case animationFailed
    case memoryWarning
    case invalidFormat
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .dataDecodingFailed:
            return "Failed to load format data"
        case .bookmarkCorrupted:
            return "Your bookmarks could not be loaded and have been reset"
        case .animationFailed:
            return "Animation could not be completed"
        case .memoryWarning:
            return "The app is using too much memory"
        case .invalidFormat:
            return "Invalid format data"
        case .networkUnavailable:
            return "Network connection unavailable"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .dataDecodingFailed:
            return "Please restart the app or check for updates"
        case .bookmarkCorrupted:
            return "Your bookmarks have been reset. Please re-add your favorites"
        case .animationFailed:
            return "Try closing and reopening the slideshow"
        case .memoryWarning:
            return "Close other apps or restart your device"
        case .invalidFormat:
            return "The format data may be corrupted"
        case .networkUnavailable:
            return "Check your internet connection"
        }
    }
}

// MARK: - Error Handler
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var showError = false
    
    private init() {}
    
    func handle(_ error: AppError) {
        DispatchQueue.main.async { [weak self] in
            self?.currentError = error
            self?.showError = true
        }
    }
    
    func handleSilently(_ error: Error) {
        print("[Error]: \(error.localizedDescription)")
    }
    
    func reset() {
        currentError = nil
        showError = false
    }
}

// MARK: - Error View Modifier
struct ErrorAlertModifier: ViewModifier {
    @ObservedObject private var errorHandler = ErrorHandler.shared
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $errorHandler.showError) {
                Button("OK") {
                    errorHandler.reset()
                }
            } message: {
                if let error = errorHandler.currentError {
                    Text(error.errorDescription ?? "An unknown error occurred")
                    if let recovery = error.recoverySuggestion {
                        Text(recovery)
                    }
                }
            }
    }
}

extension View {
    func handleErrors() -> some View {
        modifier(ErrorAlertModifier())
    }
}

// MARK: - Safe Data Operations
extension UserDefaults {
    func safelyDecode<T: Decodable>(_ type: T.Type, from key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            ErrorHandler.shared.handle(.dataDecodingFailed)
            removeObject(forKey: key)
            return nil
        }
    }
    
    func safelyEncode<T: Encodable>(_ value: T, for key: String) {
        do {
            let data = try JSONEncoder().encode(value)
            set(data, forKey: key)
        } catch {
            ErrorHandler.shared.handleSilently(error)
        }
    }
}