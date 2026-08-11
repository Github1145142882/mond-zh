//
//  system_plist.swift
//  mond
//
//  Helpers for safely editing and restoring system property lists.
//

import Foundation
import Darwin

enum SystemPlistError: Error, LocalizedError {
    case accessDenied(path: String, code: Int64)
    case invalidPlist(path: String)
    case writeFailed(path: String, code: Int32)
    case probeFailed(String)

    var errorDescription: String? {
        switch self {
        case let .accessDenied(path, code):
            return "无法访问 \(path)（错误代码：\(code)）"
        case let .invalidPlist(path):
            return "\(path) 不是有效的属性列表"
        case let .writeFailed(path, code):
            return "写入 \(path) 失败（POSIX：\(code)）"
        case let .probeFailed(message):
            return "RDAR 写入探针失败：\(message)"
        }
    }
}

private var systemPlistSandboxHandles: [Int64] = []

@discardableResult
func grantSystemPathAccess(_ path: String, createIfMissing: Bool = false) throws -> Int64 {
    let exists = FileManager.default.fileExists(atPath: path)
    var pathCString = path.utf8CString
    let handle = pathCString.withUnsafeMutableBufferPointer { buffer in
        bad_query(buffer.baseAddress, createIfMissing && !exists, nil, false)
    }
    guard handle >= 0 else {
        throw SystemPlistError.accessDenied(path: path, code: handle)
    }
    systemPlistSandboxHandles.append(handle)
    return handle
}

func loadSystemPlist(at path: String) throws -> NSMutableDictionary {
    guard FileManager.default.fileExists(atPath: path) else {
        return NSMutableDictionary()
    }
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

func systemMissingMarkerURL(named name: String) -> URL {
    URL(fileURLWithPath: AppPaths.backups).appendingPathComponent("\(name).originally-missing")
}

func recordSystemFileOriginallyMissing(named name: String) throws {
    discardSystemBackup(named: name)
    try Data().write(
        to: systemMissingMarkerURL(named: name),
        options: [.withoutOverwriting]
    )
}

func systemBackupExists(named name: String) -> Bool {
    FileManager.default.fileExists(atPath: systemBackupURL(named: name).path) ||
        FileManager.default.fileExists(atPath: systemMissingMarkerURL(named: name).path)
}

func discardSystemBackup(named name: String) {
    try? FileManager.default.removeItem(at: systemBackupURL(named: name))
    try? FileManager.default.removeItem(at: systemMissingMarkerURL(named: name))
}

func cleanupFailedSystemCreation(at path: String, named backupName: String) throws {
    let markerURL = systemMissingMarkerURL(named: backupName)
    guard FileManager.default.fileExists(atPath: markerURL.path) else { return }

    if Darwin.unlink(path) != 0 && errno != ENOENT {
        throw SystemPlistError.writeFailed(path: path, code: errno)
    }
    try FileManager.default.removeItem(at: markerURL)
}

func backupSystemFileIfNeeded(at path: String, named backupName: String) throws {
    let backupURL = systemBackupURL(named: backupName)
    let missingMarkerURL = systemMissingMarkerURL(named: backupName)
    guard !systemBackupExists(named: backupName) else { return }

    if FileManager.default.fileExists(atPath: path) {
        try FileManager.default.copyItem(at: URL(fileURLWithPath: path), to: backupURL)
    } else {
        try Data().write(to: missingMarkerURL, options: [.withoutOverwriting])
    }
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
    let exists = FileManager.default.fileExists(atPath: path)
    let flags = O_WRONLY | O_CLOEXEC | O_NOFOLLOW | (exists ? 0 : O_CREAT | O_EXCL)
    let descriptor = Darwin.open(path, flags, mode_t(0o600))
    guard descriptor >= 0 else {
        throw SystemPlistError.writeFailed(path: path, code: errno)
    }
    defer { Darwin.close(descriptor) }

    try data.withUnsafeBytes { rawBuffer in
        guard let baseAddress = rawBuffer.baseAddress else { return }
        var totalWritten = 0
        while totalWritten < rawBuffer.count {
            let result = Darwin.pwrite(
                descriptor,
                baseAddress.advanced(by: totalWritten),
                rawBuffer.count - totalWritten,
                off_t(totalWritten)
            )
            guard result > 0 else {
                throw SystemPlistError.writeFailed(path: path, code: errno)
            }
            totalWritten += result
        }
    }

    guard Darwin.ftruncate(descriptor, off_t(data.count)) == 0 else {
        throw SystemPlistError.writeFailed(path: path, code: errno)
    }
    guard Darwin.fsync(descriptor) == 0 else {
        throw SystemPlistError.writeFailed(path: path, code: errno)
    }
}

func restoreSystemFileIfBackedUp(at path: String, named backupName: String) throws -> Bool {
    let backupURL = systemBackupURL(named: backupName)
    let missingMarkerURL = systemMissingMarkerURL(named: backupName)

    if FileManager.default.fileExists(atPath: missingMarkerURL.path) {
        if FileManager.default.fileExists(atPath: path) {
            try FileManager.default.removeItem(atPath: path)
        }
        try FileManager.default.removeItem(at: missingMarkerURL)
        return true
    }

    guard FileManager.default.fileExists(atPath: backupURL.path) else { return false }

    let data = try Data(contentsOf: backupURL)
    try writeSystemData(data, to: path)
    try FileManager.default.removeItem(at: backupURL)
    return true
}
