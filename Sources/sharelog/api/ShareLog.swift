//
//  ShareLog.swift
//  sharelog
//
//  Created by Adrian Pascu on 01.12.2024.
//
import Foundation

@available(macOS 12.0, *)
class ShareLog {
	nonisolated(unsafe) static var shared: ShareLog?
	
	static func initialize(baseUrl: String, apiKey: String) throws {
		try ApiClient.initialize(baseUrl: baseUrl, apiKey: apiKey)
		
		shared = ShareLog()
	}
	
	func initGlobalErrorHandler() {
		NSSetUncaughtExceptionHandler { exception in
			let currentExceptionHandler = NSGetUncaughtExceptionHandler()

			ShareLog.shared?.handleError(exception: exception)
			currentExceptionHandler?(exception)
		}
	}
	
	private func handleError(exception: NSException) {
		let stackTrace = exception.callStackSymbols.joined(separator: "\n")
		Task {
			try await LogApi.safeShared.log(dto: LogDto(stackTrace: stackTrace ))
		}
	}
	
	func stop(){
		ShareLog.shared = nil
		ApiClient.shared = nil
		LogApi.shared = nil
	}
}
