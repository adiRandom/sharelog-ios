//
//  Lateinit.swift
//  sharelog
//
//  Created by Adrian Pascu on 01.12.2024.
//

@propertyWrapper
internal public struct Lateinit<Value> {
	
	var storage: Value?
	
	public init() {
		storage = nil
	}
	
	public var wrappedValue: Value {
		get {
			guard let storage = storage else {
				fatalError("Trying to access LateInit.value before setting it.")
			}
			return storage
		}
		set {
			storage = newValue
		}
	}
}
