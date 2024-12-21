//
//  CrashReporter.swift
//  ShareLog
//
//  Created by Adrian Pascu on 21.12.2024.
//

import Foundation
import UIKit

// --------------------------------------------------------------------------

// MARK: - CrashEyeDelegate

// --------------------------------------------------------------------------
public protocol CrashEyeDelegate: NSObjectProtocol {
	func crashEyeDidCatchCrash(with model: CrashModel)
}

// --------------------------------------------------------------------------

// MARK: - WeakCrashEyeDelegate

// --------------------------------------------------------------------------
class WeakCrashEyeDelegate: NSObject {
	weak var delegate: CrashEyeDelegate?

	init(delegate: CrashEyeDelegate) {
		super.init()
		self.delegate = delegate
	}
}

// --------------------------------------------------------------------------

// MARK: - CrashModelType

// --------------------------------------------------------------------------
public enum CrashModelType: Int {
	case signal = 1
	case exception = 2
}

// --------------------------------------------------------------------------

// MARK: - CrashModel

// --------------------------------------------------------------------------
public final class CrashModel: NSObject {
	let type: CrashModelType
	let name: String
	let reason: String
	let appinfo: String
	let callStack: String

	init(type: CrashModelType,
	     name: String,
	     reason: String,
	     appinfo: String,
	     callStack: String)
	{
		self.type = type
		self.name = name
		self.reason = reason
		self.appinfo = appinfo
		self.callStack = callStack
	}
}

private struct DeviceInfo {
	let deviceModel: String
	let systemName: String
	let systemVersion: String

	@MainActor
	init() {
		self.deviceModel = UIDevice.current.model
		self.systemName = UIDevice.current.systemName
		self.systemVersion = UIDevice.current.systemVersion
	}
}

// --------------------------------------------------------------------------

// MARK: - GLOBAL VARIABLE

// --------------------------------------------------------------------------
private nonisolated(unsafe) var app_old_exceptionHandler: (@convention(c) (NSException) -> Swift.Void)?

// --------------------------------------------------------------------------

// MARK: - CrashEye

// --------------------------------------------------------------------------
public class CrashEye: NSObject {
	// --------------------------------------------------------------------------

	// MARK: OPEN

	internal private(set) nonisolated(unsafe) static var isOpen: Bool = false
	fileprivate nonisolated(unsafe) static var deviceInfo: DeviceInfo? = nil

	@MainActor
	override init() {
		super.init()
		CrashEye.deviceInfo = DeviceInfo()
	}

	// --------------------------------------------------------------------------

	// MARK: OPEN FUNCTION

	// --------------------------------------------------------------------------
	open class func add(delegate: CrashEyeDelegate) {
		// delete null week delegate
		self.delegates = self.delegates.filter {
			$0.delegate != nil
		}

		// judge if contains the delegate from parameter
		let contains = self.delegates.contains {
			$0.delegate?.hash == delegate.hash
		}
		// if not contains, append it with weak wrapped
		if contains == false {
			let week = WeakCrashEyeDelegate(delegate: delegate)
			self.delegates.append(week)
		}

		if self.delegates.count > 0 {
			self.open()
		}
	}

	open class func remove(delegate: CrashEyeDelegate) {
		self.delegates = self.delegates.filter {
			// filter null weak delegate
			$0.delegate != nil
		}.filter {
			// filter the delegate from parameter
			$0.delegate?.hash != delegate.hash
		}

		if self.delegates.count == 0 {
			self.close()
		}
	}

	// --------------------------------------------------------------------------

	// MARK: PRIVATE FUNCTION

	// --------------------------------------------------------------------------
	private class func open() {
		guard self.isOpen == false else {
			return
		}
		CrashEye.isOpen = true

		app_old_exceptionHandler = NSGetUncaughtExceptionHandler()
		NSSetUncaughtExceptionHandler(CrashEye.RecieveException)
		self.setCrashSignalHandler()
	}

	private class func close() {
		guard self.isOpen == true else {
			return
		}
		CrashEye.isOpen = false
		NSSetUncaughtExceptionHandler(app_old_exceptionHandler)
	}

	private class func setCrashSignalHandler() {
		signal(SIGABRT, CrashEye.RecieveSignal)
		signal(SIGILL, CrashEye.RecieveSignal)
		signal(SIGSEGV, CrashEye.RecieveSignal)
		signal(SIGFPE, CrashEye.RecieveSignal)
		signal(SIGBUS, CrashEye.RecieveSignal)
		signal(SIGPIPE, CrashEye.RecieveSignal)
		// http://stackoverflow.com/questions/36325140/how-to-catch-a-swift-crash-and-do-some-logging
		signal(SIGTRAP, CrashEye.RecieveSignal)
	}

	private static let RecieveException: @convention(c) (NSException) -> Swift.Void = {
		exteption in
		if app_old_exceptionHandler != nil {
			app_old_exceptionHandler!(exteption)
		}

		guard CrashEye.isOpen == true else {
			return
		}

		let callStack = exteption.callStackSymbols.joined(separator: "\r")
		let reason = exteption.reason ?? ""
		let name = exteption.name
		let appinfo = CrashEye.appInfo()

		let model = CrashModel(type: CrashModelType.exception,
		                       name: name.rawValue,
		                       reason: reason,
		                       appinfo: appinfo,
		                       callStack: callStack)
		for delegate in CrashEye.delegates {
			delegate.delegate?.crashEyeDidCatchCrash(with: model)
		}
	}

	private static let RecieveSignal: @convention(c) (Int32) -> Void = {
		signal in

		guard CrashEye.isOpen == true else {
			return
		}

		var stack = Thread.callStackSymbols
		stack.removeFirst(2)
		let callStack = stack.joined(separator: "\r")
		let reason = "Signal \(CrashEye.name(of: signal))(\(signal)) was raised.\n"
		let appinfo = CrashEye.appInfo()

		let model = CrashModel(type: CrashModelType.signal,
		                       name: CrashEye.name(of: signal),
		                       reason: reason,
		                       appinfo: appinfo,
		                       callStack: callStack)

		for delegate in CrashEye.delegates {
			delegate.delegate?.crashEyeDidCatchCrash(with: model)
		}

		CrashEye.killApp()
	}

	private class func appInfo() -> String {
		let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") ?? ""
		let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? ""
		let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? ""

		let deviceModel = CrashEye.deviceInfo?.deviceModel ?? ""
		let systemName = CrashEye.deviceInfo?.systemName ?? ""
		let systemVersion = CrashEye.deviceInfo?.systemVersion ?? ""

		return "App: \(displayName) \(shortVersion)(\(version))\n" +
			"Device:\(deviceModel)\n" + "OS Version:\(systemName) \(systemVersion)"
	}

	private class func name(of signal: Int32) -> String {
		switch signal {
		case SIGABRT:
			return "SIGABRT"
		case SIGILL:
			return "SIGILL"
		case SIGSEGV:
			return "SIGSEGV"
		case SIGFPE:
			return "SIGFPE"
		case SIGBUS:
			return "SIGBUS"
		case SIGPIPE:
			return "SIGPIPE"
		default:
			return "OTHER"
		}
	}

	private class func killApp() {
		NSSetUncaughtExceptionHandler(nil)

		signal(SIGABRT, SIG_DFL)
		signal(SIGILL, SIG_DFL)
		signal(SIGSEGV, SIG_DFL)
		signal(SIGFPE, SIG_DFL)
		signal(SIGBUS, SIG_DFL)
		signal(SIGPIPE, SIG_DFL)

		kill(getpid(), SIGKILL)
	}

	// --------------------------------------------------------------------------

	// MARK: PRIVATE PROPERTY

	// --------------------------------------------------------------------------
	fileprivate nonisolated(unsafe) static var delegates = [WeakCrashEyeDelegate]()
}
