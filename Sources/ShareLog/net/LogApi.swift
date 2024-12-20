//
//  LogApi.swift
//  sharelog
//
//  Created by Adrian Pascu on 01.12.2024.
//

import Foundation

@available(iOS 15.0, *)
internal actor LogApi {
	static var shared: LogApi? = LogApi()
	
	static var safeShared: LogApi{
		get throws {
			guard let instance = shared else{
				throw ShareLogError(message: "Sharelog not initialized")
			}
			
			return instance
		}
	}

	func log(dto: LogDto) async throws -> Response<EmptyResponse> {
		return try await ApiClient.safeShared.post(endpoint: "/log", body: dto, responseType: EmptyResponse.self)
	}
}
