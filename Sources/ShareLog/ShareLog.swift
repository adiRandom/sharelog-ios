// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

@available(macOS 12.0, iOS 13.0, *)
public class ShareLogClient {
	public nonisolated(unsafe) static var shared: ShareLogClient?
	
	public static func setup(baseUrl: String, apiKey: String) throws {
		try ApiClient.initialize(baseUrl: baseUrl, apiKey: apiKey)
		
		shared = ShareLogClient()
	}
	
	public func initGlobalErrorHandler() {
		NSSetUncaughtExceptionHandler { exception in
			let currentExceptionHandler = NSGetUncaughtExceptionHandler()

			ShareLogClient.shared?.handleError(exception: exception)
			currentExceptionHandler?(exception)
		}
	}
	
	private func handleError(exception: NSException) {
		let stackTrace = exception.callStackSymbols.joined(separator: "\n")
		Task {
			try await LogApi.safeShared.log(dto: LogDto(stackTrace: stackTrace ))
		}
	}
	
	public func stop(){
		ShareLogClient.shared = nil
		ApiClient.shared = nil
		LogApi.shared = nil
	}
}
