//
//  Response.swift
//  sharelog
//
//  Created by Adrian Pascu on 01.12.2024.
//

internal enum Response<T: Decodable & Sendable>: Sendable{
	case success(data: T)
	case error(error: APIError)
}

internal struct EmptyResponse: Decodable, Sendable{
	
}


internal struct APIError: Decodable, Error {
	let message: String
	let code: Int
}

extension Response: Decodable {
	enum CodingKeys: String, CodingKey {
		case data
		case error
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		// Check for error first
		if let error = try container.decodeIfPresent(APIError.self, forKey: .error) {
			self = .error(error: error)
		} else if let data = try container.decodeIfPresent(T.self, forKey: .data) {
			self = .success(data: data)
		} else {
			throw DecodingError.dataCorrupted(
				DecodingError.Context(
					codingPath: decoder.codingPath,
					debugDescription: "Neither data nor error found"
				)
			)
		}
	}
}
