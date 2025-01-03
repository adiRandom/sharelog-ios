//
//  ApiClient.swift
//  sharelog
//
//  Created by Adrian Pascu on 01.12.2024.
//

import Foundation

internal struct ApiClient {
	private let session = URLSession.shared
	private let baseUrl: URL
	private let apiKey: String
	
	static let API_KEY_HEADER = "ApiKey"
	static let ERROR_KEY = "error"
	
	nonisolated(unsafe) static var shared: ApiClient?
	static var safeShared: ApiClient {
		get throws {
			guard let instance = shared else {
				throw ShareLogError(message: "Sharelog not initialized")
			}
			
			return instance
		}
	}
	
	static func initialize(baseUrl: String, apiKey: String) throws {
		guard let client = ApiClient(baseUrl: baseUrl, apiKey: apiKey) else {
			throw ShareLogError(message: "Invalid base url")
		}
		
		shared = client
	}
	
	init?(baseUrl: String, apiKey: String) {
		guard let url = URL(string: baseUrl) else {
			return nil
		}
		
		self.baseUrl = url
		self.apiKey = apiKey
	}
	
	private func applyAuth(request: inout URLRequest) {
		request.setValue(apiKey, forHTTPHeaderField: ApiClient.API_KEY_HEADER)
	}
	
	func post<T: Encodable, S: Decodable>(
		endpoint: String,
		body: T?,
		headers: [String: String]? = nil,
		responseType: S.Type,
		complete: @escaping @Sendable (Response<T>?, Error?) -> Void
	) throws {
		let url = baseUrl.appendingPathComponent(endpoint)
		var request = URLRequest(url: url)
		
		request.httpMethod = "POST"
		headers?.forEach { key, value in
			request.setValue(value, forHTTPHeaderField: key)
		}
		
		if let body = body {
			request.httpBody = try JSONEncoder().encode(body)
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		}
		
		applyAuth(request: &request)
		performRequest(request, complete: complete)
	}
	
	private func performRequest<T: Decodable>(
		_ request: URLRequest,
		complete: @escaping @Sendable (Response<T>?, Error?) -> Void
	) {
		session.dataTask(with: request) { data, response, error in
			// Ensure valid response
			if error != nil {
				complete(nil, error)
			}
			 
			guard let httpResponse = response as? HTTPURLResponse else{
				return complete(nil, ShareLogError(message: "Invalid api response"))
			}
							
			if !((200 ... 299).contains(httpResponse.statusCode)) {
				complete(nil, URLError(.badServerResponse))
			}
			
			// Decode the response
			do {
				if let unwrappedData = data {
					let decodedData = try JSONDecoder().decode(Response<T>.self, from: unwrappedData)
					complete(decodedData, nil)
				}
			}
			catch {
				complete(nil, error)
			}
		}
	}
}
