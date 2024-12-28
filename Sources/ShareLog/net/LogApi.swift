//
//  LogApi.swift
//  sharelog
//
//  Created by Adrian Pascu on 01.12.2024.
//

import Foundation

@available(macOS 12.0, iOS 15.0, *)
internal struct LogApi {
	nonisolated(unsafe) static var shared: LogApi? = LogApi()
	
	static var safeShared: LogApi{
		get throws {
			guard let instance = shared else{
				throw ShareLogError(message: "Sharelog not initialized")
			}
			
			return instance
		}
	}

	func log(dto: LogDto) throws{
		try ApiClient.safeShared.post(endpoint: "/log", body: dto, responseType: EmptyResponse.self){_, _ in
			
		}
	}
}
