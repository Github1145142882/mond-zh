//
//  system_plist.swift
//  mond
//
//  Helpers for safely editing and restoring system property lists.
//

import Foundation

enum SystemPlistError: Error, LocalizedError {
    case accessDenied(path: String, code: Int64)
    case invalidPlist(path: String)
    case missingBackup(String)

    var errorDescription: String? {
        switch self {
        case let .accessDenied(path, code):
            return "无法访问 \(path)（错误代码：\(code)）"
        case let .invalidPlist(path):
            return "\(path) 不是有效的属性列表"
        case let .missingBackup(name):
            return "找不到备份：\(name)"
        }
    }
}

private var systemPlistSandboxHandles: [Int64] = []

@discardableResult
func grantSystemPathAccess(_ path: String) throws -> Int64 {
    let accessPath: String
    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue {
        accessPath = path
    } else {
        accessPath = URL(fileURLWithPath: path).deletingLastPathComponent().path
    }

    var pathCString = accessPath.utf8CString
    let handle = pathCString.withUnsafeMutableBufferPointer { buffer in
        bad_query(buffer.baseAddress, false, nil, false)
    }
    guard handle >= 0 else {
        throw SystemPlistError.accessDenied(path: accessPath, code: handle)
    }
    systemPlistSandboxHandles.append(handle)
    return handle
}

func loadSystemPlist(at path: String) throws -> NSMutableDictionary {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    guard let dictionary = try PropertyListSerialization.propertyList(
        from: data,
        options: [.mutableContainersAndLeaves],
        format: nil
    ) as? NSMutableDictionary else {
        throw SystemPlistError.invalidPlist(path: path)
    }
    return dictionary
}

func systemBackupURL(named name: String) -> URL {
    URL(fileURLWithPath: AppPaths.backups).appendingPathComponent(name)
}

func backupSystemFileIfNeeded(at path: String, named backupName: String) throws {
    let backupURL = systemBackupURL(named: backupName)
    guard !FileManager.default.fileExists(atPath: backupURL.path) else { return }
    try FileManager.default.copyItem(at: URL(fileURLWithPath: path), to: backupURL)
}

func writeSystemPlist(_ dictionary: NSDictionary, to path: String) throws {
    let data = try PropertyListSerialization.data(
        fromPropertyList: dictionary,
        format: .binary,
        options: 0
    )
    try writeSystemData(data, to: path)
}

func writeSystemData(_ data: Data, to path: String) throws {
    let targetURL = URL(fileURLWithPath: path)
    let temporaryURL = targetURL.deletingLastPathComponent()
        .appendingPathComponent(".\(targetURL.lastPathComponent).\(UUID().uuidString).tmp")

    try data.write(to: temporaryURL, options: [.withoutOverwriting])
    defer { try? FileManager.default.removeItem(at: temporaryURL) }

    _ = try FileManager.default.replaceItemAt(targetURL, withItemAt: temporaryURL)
}

func restoreSystemFileIfBackedUp(at path: String, named backupName: String) throws -> Bool {
    let backupURL = systemBackupURL(named: backupName)
    guard FileManager.default.fileExists(atPath: backupURL.path) else { return false }

    let data = try Data(contentsOf: backupURL)
    try writeSystemData(data, to: path)
    try FileManager.default.removeItem(at: backupURL)
    return true
}
