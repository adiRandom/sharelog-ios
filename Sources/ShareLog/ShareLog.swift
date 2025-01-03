// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

private let logFileName = "sharelog.json"

public class ShareLogClient: NSObject {
	public nonisolated(unsafe) static var shared: ShareLogClient?
	private let logFile = FileLog(fileName: logFileName)
	
	override init() {
		if logFile.exists() {
			// Send log then delete
			do {
				let log = try logFile.read()
				try LogApi.safeShared.log(dto: log)
				try logFile.clear()
			}
			catch {
				print("Error sending log file: \(error)")
			}
		}
		
		logFile.create()
	}
	
	public static func setup(baseUrl: String, apiKey: String) throws {
		try ApiClient.initialize(baseUrl: baseUrl, apiKey: apiKey)
		
		shared = ShareLogClient()
	}
	
	public func initGlobalErrorHandler() {
		CrashEye.add(delegate: self)
	}
	
	public func stop() {
		ShareLogClient.shared = nil
		ApiClient.shared = nil
		LogApi.shared = nil
	}
}

extension ShareLogClient: CrashEyeDelegate {
	public func crashEyeDidCatchCrash(with model: CrashModel) {
		let stackTrace = model.callStack
		print("Log: " + stackTrace)
		logFile.write(log: LogDto(stackTrace: stackTrace))
	}
}
