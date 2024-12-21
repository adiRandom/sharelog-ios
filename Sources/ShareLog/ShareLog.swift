// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

@available(macOS 12.0, iOS 15.0, *)
public class ShareLogClient:NSObject{
	public nonisolated(unsafe) static var shared: ShareLogClient?
	
	public static func setup(baseUrl: String, apiKey: String) throws {
		try ApiClient.initialize(baseUrl: baseUrl, apiKey: apiKey)
		
		shared = ShareLogClient()
	}
	
	public func initGlobalErrorHandler() {
		CrashEye.add(delegate: self)
	}
	
	
	public func stop(){
		ShareLogClient.shared = nil
		ApiClient.shared = nil
		LogApi.shared = nil
	}
}

extension ShareLogClient:CrashEyeDelegate{
	public func crashEyeDidCatchCrash(with model: CrashModel) {
		let stackTrace = model.callStack
		print("Log: " + stackTrace)
		Task {
			try await LogApi.safeShared.log(dto: LogDto(stackTrace: stackTrace ))
		}
	}
	
}
