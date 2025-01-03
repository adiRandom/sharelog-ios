//
//  FileLog.swift
//  ShareLog
//
//  Created by Adrian Pascu on 03.01.2025.
//
import Foundation

package class FileLog {
	private var fileHandle: FileHandle?
	private let fileURL: URL

	init(fileName: String) {
		let fileManager = FileManager.default
		let documentDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

		fileURL = documentDirectory.appendingPathComponent(fileName)
	}

	func write(log: LogDto) {
		guard let fileHandle = fileHandle else {
			print("File handle is not available")
			return
		}
		do {
			let json = try JSONEncoder().encode(log)
			fileHandle.write(json)
		} catch {
			print("Error serializing object: \(error)")
		}
	}

	func read() throws -> LogDto {
		let data = try Data(contentsOf: fileURL)
		let decoder = JSONDecoder()
		return try decoder.decode(LogDto.self, from: data)
	}

	func clear() throws {
		try FileManager.default.removeItem(at: fileURL)
	}

	func exists() -> Bool {
		return FileManager.default.fileExists(atPath: fileURL.path)
	}

	func create() {
		let fileManager = FileManager.default

		// Create the file if it doesn't exist
		if !fileManager.fileExists(atPath: fileURL.path) {
			fileManager.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
		}

		do {
			// Open the file for writing
			fileHandle = try FileHandle(forWritingTo: fileURL)
		} catch {
			print("Error opening file: \(error)")
		}
	}

	deinit {
		// Close the file when the instance is deallocated
		fileHandle?.closeFile()
	}
}
