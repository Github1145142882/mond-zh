//
//  ContentView.swift
//  mond
//
//  Created by ruter on 16.07.26.
//

import SwiftUI
import PartyUI

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @AppStorage("mg_devicename") private var mg_devicename: String = ""
    @AppStorage("token") private var token: String = ""
    @AppStorage("rdar_fix_enabled") private var rdar_fix_enabled: Bool = false
    @AppStorage("lockscreen_footnote_enabled") private var lockscreen_footnote_enabled: Bool = false
    @AppStorage("lockscreen_footnote") private var lockscreen_footnote: String = ""
    
    @State private var mg_dict_now: NSMutableDictionary = NSMutableDictionary()
    @State private var is_valid: Bool = false
    
    @State private var subtype: Int = 0
    @State private var og_subtype: Int = 0
    @State private var og_devicename: String = ""
    @State private var enable_devicename: Bool = false
    @State private var product_type: String = ""
    
    @State private var show_settings: Bool = false
    
    private var mg_valid: Bool {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: TweakPaths.gestalt)) else { return false }
        return (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) != nil
    }
    
    private var mg_empty: Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: TweakPaths.gestalt),
              let size = attributes[.size] as? UInt64 else { return false }

        return size == 0
    }
    
    var valid: Bool {
        (sandbox_extension_consume(token) ?? -1) >= 0
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !mg_valid || mg_empty {
                    Section {
                        if mg_empty {
                            PlainAlert(title: "请勿重启！", icon: "exclamationmark.triangle.fill", text: "MobileGestalt.plist 文件似乎为空。", color: Color.yellow)
                        }
                        
                        if !mg_valid {
                            PlainAlert(title: "请勿重启！", icon: "exclamationmark.triangle.fill", text: "MobileGestalt.plist 文件似乎无效。", color: Color.yellow)
                        }
                    } header: {
                        Label("警告", systemImage: "exclamationmark.triangle")
                    } footer: {
                        Text("现在重启可能导致设备无限重启。请尝试点击“还原修改”；如果警告仍未消失，请勿重启设备。")
                    }
                }
                
                Section {
                    Button {
                        mg_apply()
                    } label: {
                        Text("应用修改")
                    }
                    
                    Button {
                        mg_revert()
                    } label: {
                        Text("还原修改")
                    }
                } footer: {
                    Text("**警告：** 错误使用这些修改可能导致设备功能异常，甚至无法正常启动！")
                }
                
                Section {
                    Picker(selection: $subtype) {
                        Text("原始值（\(og_subtype)）").tag(og_subtype)
                        if is_device_good() {
                            Text("停用灵动岛").tag(2436)
                        }
                        Text("iPhone 14 Pro").tag(2436)
                        Text("iPhone 14 Pro Max").tag(2796)
                        Text("iPhone 15 Pro Max").tag(2976)
                        if doubleSystemVersion() >= 18.0 {
                            Text("iPhone 16 Pro").tag(2622)
                            Text("iPhone 16 Pro Max").tag(2868)
                        }
                        if doubleSystemVersion() >= 26.0 {
                            Text("iPhone Air").tag(2736)
                        }
                        if hasHomeButton() {
                            Text("iPhone X 手势").tag(2436)
                        }
                    } label: {
                        HStack {
                            Text("子类型")
                            Spacer()
                        }
                    }
                    
                    Toggle("自定义设备名称", isOn: $enable_devicename)
                    
                    if enable_devicename {
                        TextField("设备名称", text: $mg_devicename)
                    }

                    Toggle("灵动岛状态栏／RDAR 修复", isOn: $rdar_fix_enabled)
                        .disabled(rdarFixMode == nil)
                } header: {
                    Label("设备外观", systemImage: "paintbrush.pointed")
                } footer: {
                    if rdarFixMode == nil {
                        Text("当前机型不需要或不支持 RDAR 分辨率修复。")
                    } else {
                        Text("修复在非原生灵动岛机型上启用灵动岛后可能出现的状态栏错位。")
                    }
                }
                
                // basic tweak toggles
                Section {
                    PlainToggle(text: "灵动岛", minSupportedVersion: 19.0, isOn: mg_key_binding(["YlEtTtHlNesRBMal1CqRaA"]))
                    PlainToggle(text: "全天候显示", minSupportedVersion: 18.0, isOn: mg_key_binding(["j8/Omm6s1lsmTDFsXjsBfA", "2OOJf1VhaM7NxfRok3HbWQ"]))
                    PlainToggle(text: "全天候显示鲜艳效果", minSupportedVersion: 18.0, isOn: mg_key_binding(["ykpu7qyhqFweVMKtxNylWA"]))
                    PlainToggle(text: "充电上限", minSupportedVersion: 17.0, isOn: mg_key_binding(["37NVydb//GP/GrhuTN+exg"]))
                    PlainToggle(text: "开机提示音", isOn: mg_key_binding(["QHxt+hGLaBPbQJbXiUJX3w"]))
                    PlainToggle(text: "液态玻璃低电量模式", minSupportedVersion: 19.0, isOn: mg_key_binding(["SAGvsp6O6kAQ4fEfDJpC4Q"]))
                    PlainToggle(text: "关闭壁纸视差效果", isOn: mg_key_binding(["UIParallaxCapability"], on_val: 0))
                } header: {
                    Label("软件功能", systemImage: "gearshape")
                }

                Section {
                    Toggle("显示自定义文字", isOn: $lockscreen_footnote_enabled)

                    if lockscreen_footnote_enabled {
                        TextField("锁屏底部文字", text: $lockscreen_footnote, axis: .vertical)
                            .lineLimit(1...3)
                    }
                } header: {
                    Label("锁定屏幕", systemImage: "lock")
                } footer: {
                    Text("文字会显示在锁屏底部，应用后需要重载桌面。")
                }
                
                Section {
                    PlainToggle(text: "相机控制", minSupportedVersion: 18.0, isOn: mg_key_binding(["CwvKxM2cEogD3p+HYgaW0Q", "oOV1jhJbdV3AddkcCg0AEA"]))
                    PlainToggle(text: "操作按钮", minSupportedVersion: 17.0, isOn: mg_key_binding(["cT44WE1EohiwRzhsZ8xEsw"]))
                    PlainToggle(text: "车祸检测", isOn: mg_key_binding(["HCzWusHQwZDea6nNhaKndw"]))
                    if hasHomeButton() {
                        PlainToggle(text: "启用轻点唤醒", isOn: mg_key_binding(["yZf3GTRMGTuwSV/lD7Cagw"]))
                    }
                    PlainToggle(text: "脉宽调制", minSupportedVersion: 19.0, isOn: mg_key_binding(["6IejgN+1Fmu5/QrZFOIeNw"]))
                } header: {
                    Label("硬件功能", systemImage: "iphone")
                }
                
                Section {
                    PlainToggle(text: "安全研究设备界面", minSupportedVersion: 26.0, isOn: mg_key_binding(["XYlJKKkj2hztRP1NWWnhlw"]))
                    PlainToggle(text: "停用地区限制", isOn: mg_region_restrict_binding())
                    PlainToggle(text: "Apple 智能", minSupportedVersion: 18.1, isOn: mg_key_binding(["A62OafQ85EJAiiqKn4agtg"]))
                    HStack(spacing: 10) {
                        Picker("设备伪装", selection: $product_type) {
                            Text("默认").tag(machine_name())
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                if doubleSystemVersion() >= 17.4 {
                                    Text("iPad Pro 11-inch (M4)").tag("iPad16,3")
                                    Text("iPad Pro 11-inch (M4, Cellular)").tag("iPad16,4")
                                }
                                Text("iPad Pro 11-inch (4th Gen)").tag("iPad14,3")
                                Text("iPad Pro 11-inch (4th Gen, Cellular)").tag("iPad14,4")
                            } else {
                                Text("iPhone 15 Pro").tag("iPhone16,1")
                                Text("iPhone 15 Pro Max").tag("iPhone16,2")
                                if doubleSystemVersion() >= 18.0 {
                                    Text("iPhone 16").tag("iPhone17,3")
                                    Text("iPhone 16 Plus").tag("iPhone17,4")
                                    Text("iPhone 16 Pro").tag("iPhone17,1")
                                    Text("iPhone 16 Pro Max").tag("iPhone17,2")
                                }
                                if doubleSystemVersion() >= 19.0 {
                                    Text("iPhone 17").tag("iPhone18,3")
                                    Text("iPhone 17 Pro").tag("iPhone18,1")
                                    Text("iPhone 17 Pro Max").tag("iPhone18,2")
                                    Text("iPhone Air").tag("iPhone18,4")
                                }
                            }
                        }
                        
                        Button {
                            Alertinator.shared.alert(
                                title: "设备伪装说明",
                                body: "仅在需要下载 Apple 智能时伪装设备型号。此操作可能导致面容 ID 失效。如果恢复原始型号后仍想保留 Apple 智能，请勿再次进入“设置”中的“Apple 智能与 Siri”菜单。"
                            )
                        } label: {
                            Image(systemName: "info.circle")
                                .frame(width: 24, height: 22)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Label("可用性", systemImage: "checklist")
                }
                
                Section {
                    let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary
                    
                    PlainToggle(text: "允许安装 iPadOS App", isOn: mg_key_binding(["9MZ5AdH43csAUajl/dU+IQ"], type: [Int].self, default_val: [1], on_val: [1, 2]))
                    PlainToggle(text: "Apple Pencil 设置", isOn: mg_key_binding(["yhHcB0iH0d1XzPO/CFd3ow"]))
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        PlainToggle(text: "台前调度", isOn: mg_key_binding(["qeaj75wk3HF4DwQ8qbIi7g"]))
                    }
                    PlainToggle(
                        text: "iPadOS 界面",
                        infoType: .warning,
                        infoMessage: "这是一项非常危险的修改！如果你使用字母数字密码，请绝对不要启用。请勿关闭“在台前调度中显示程序坞”，否则设备旋转到横屏时可能无限重启。即使遵守这些要求，也可能出现系统不稳定、App 数据意外丢失等严重问题。请自行承担使用风险。",
                        isOn: mg_trollpad_binding()
                    )
                    .disabled(cache_extra?["+3Uf0Pm5F8Xy7Onyvko0vA"] as? String != "iPhone")
                } header: {
                    Label("iPadOS 功能", systemImage: "ipad")
                }
                
                Section {
                    PlainToggle(text: "内部存储", isOn: mg_key_binding(["LBJfwOEzExRxzlAnSuI7eg"]))
                    PlainToggle(text: "内部功能", isOn: mg_internal_binding())
                    PlainToggle(text: "在所有 App 中显示 Metal HUD", isOn: mg_key_binding(["EqrsVvjcYDdxHBiQmGhAWw"]))
                } header: {
                    Label("内部选项", systemImage: "ant")
                }
            }
            .navigationTitle("mond")
            .tint(Color("AccentColor"))
            .onAppear {
                if !valid {
                    state.exploit_succeeded = grant_mg_write() >= 0
                } else {
                    print("(mond) valid token saved, skipping exploit")
                    state.exploit_succeeded = true
                }
                
                mg_load()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            show_settings = true
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
            }
            .sheet(isPresented: $show_settings) {
                SettingsView()
            }
        }
    }
    
    private enum MGViewError: Error, LocalizedError {
        case missingArtworkSubtype
        case missingArtworkDeviceName
        
        var errorDescription: String? {
            switch self {
            case .missingArtworkSubtype:
                return "无法获取 ArtworkDeviceSubType！"
            case .missingArtworkDeviceName:
                return "无法获取 ArtworkDeviceProductDescription！"
            }
        }
    }
    
    private func mg_load() {
        do {
            let mg_url_now = URL(fileURLWithPath: TweakPaths.gestalt)
            mg_dict_now = try NSMutableDictionary(contentsOf: mg_url_now, error: ())
            
            // this'll cache gestalt and put it in a safe place
            let mg_url_saved = URL(fileURLWithPath: AppPaths.backups).appendingPathComponent("SavedGestalt.plist")
            
            if !FileManager.default.fileExists(atPath: mg_url_saved.path) {
                try FileManager.default.copyItem(at: mg_url_now, to: mg_url_saved)
            }
            
            // get original gestalt values
            let mg_saved_dict = try NSMutableDictionary(contentsOf: mg_url_saved, error: ())
            let og_cache_extra = mg_saved_dict["CacheExtra"] as? NSMutableDictionary ?? NSMutableDictionary()
            let og_artwork = og_cache_extra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary ?? NSMutableDictionary()
            
            guard let ogSubtype = og_artwork["ArtworkDeviceSubType"] as? Int else { throw MGViewError.missingArtworkSubtype }
            og_subtype = ogSubtype
            
            guard let ogDeviceName = og_artwork["ArtworkDeviceProductDescription"] as? String else { throw MGViewError.missingArtworkDeviceName }
            
            // now get current gestalt values
            let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary ?? NSMutableDictionary()
            
            let artwork = cache_extra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary ?? NSMutableDictionary()
            
            subtype = artwork["ArtworkDeviceSubType"] as? Int ?? ogSubtype // fallback
            mg_devicename = artwork["ArtworkDeviceProductDescription"] as? String ?? ogDeviceName
            
            // assume it's been changed
            if mg_devicename != ogDeviceName {
                enable_devicename = true
            }
            
            if let productType = cache_extra["h9jDsbgj7xIVeIQ8S3/X3Q"] as? String, !productType.isEmpty {
                product_type = productType
            } else {
                product_type = machine_name()
            }
        } catch {
            print("(mg) failed to load data: \(error)")
            Alertinator.shared.alert(title: "无法加载当前 MobileGestalt！", body: "请重新启动 App 后重试，并查看日志了解详细信息。")
        }
    }
    
    private func mg_apply() {
        do {
            let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary ?? NSMutableDictionary()
            if !product_type.isEmpty {
                cache_extra["h9jDsbgj7xIVeIQ8S3/X3Q"] = product_type
            }
            
            let artwork_dict = cache_extra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary ?? NSMutableDictionary()
            artwork_dict["ArtworkDeviceSubType"] = subtype
            if enable_devicename {
                artwork_dict["ArtworkDeviceProductDescription"] = mg_devicename
            }
            
            let data = try PropertyListSerialization.data(fromPropertyList: mg_dict_now, format: .xml, options: 0)

            try applySystemTweaks()
            try mg_write(data)
            mg_dict_now = NSMutableDictionary()
            enable_devicename = false

            print("(mg) successfully overwrote mobilegestalt!")
            Alertinator.shared.alert(title: "修改已成功应用！", body: "请重载桌面以使修改生效。部分修改可能需要重启设备。", actionLabel: "重载桌面", action: {
                state.respring()
            })
        } catch {
            print("(mond) failed to apply tweaks: \(error)")
            Alertinator.shared.alert(title: "无法应用修改！", body: "\(error.localizedDescription)\n请查看日志了解详细信息。")
        }
    }
    
    private func mg_revert() {
        do {
            let backup_url = URL(fileURLWithPath: AppPaths.backups).appendingPathComponent("SavedGestalt.plist")
            let backup_data = try Data(contentsOf: backup_url)
            try mg_write(backup_data)
            try restoreAllSystemTweaks()

            rdar_fix_enabled = false
            lockscreen_footnote_enabled = false

            print("(mg) successfully reverted mobilegestalt!)")
            Alertinator.shared.alert(title: "修改已成功还原！", body: "请重启设备以使还原生效。")
        } catch {
            // The direct file write path now surfaces the underlying error through the catch.
            print("(mg) failed to revert mobilegestalt: \(error)")
            Alertinator.shared.alert(title: "无法还原修改！", body: "\(error.localizedDescription)\n请查看日志了解错误信息。")
        }
    }

    private enum RDARFixMode {
        case legacyNotch
        case modernNotch
        case homeButton
    }

    private var rdarFixMode: RDARFixMode? {
        switch machine_name() {
        case "iPhone11,2", "iPhone11,4", "iPhone11,6", "iPhone11,8",
             "iPhone12,1", "iPhone12,3", "iPhone12,5":
            return .legacyNotch
        case "iPhone13,2", "iPhone13,3", "iPhone13,4", "iPhone14,2",
             "iPhone14,3", "iPhone14,5", "iPhone14,7", "iPhone14,8", "iPhone17,5":
            return .modernNotch
        case "iPhone12,8", "iPhone14,6":
            return .homeButton
        default:
            return nil
        }
    }

    private func rdarCanvasSize() -> (width: Int, height: Int)? {
        guard let rdarFixMode else { return nil }
        switch rdarFixMode {
        case .legacyNotch:
            return (828, 1791)
        case .homeButton:
            return (1000, 1779)
        case .modernNotch:
            switch subtype {
            case 2556: return (1179, 2556)
            case 2796: return (1290, 2796)
            case 2622: return (1206, 2622)
            case 2868: return (1320, 2868)
            case 2736: return (1260, 2736)
            default: return (2868, 1320)
            }
        }
    }

    private func applySystemTweaks() throws {
        try applyRDARFix()
        try applyLockScreenFootnote()
    }

    private func applyRDARFix() throws {
        let backupName = "IOMobileGraphicsFamily.plist"
        let backupExists = FileManager.default.fileExists(atPath: systemBackupURL(named: backupName).path)
        guard rdar_fix_enabled || backupExists else { return }
        try grantSystemPathAccess(TweakPaths.graphics)

        guard rdar_fix_enabled else {
            _ = try restoreSystemFileIfBackedUp(at: TweakPaths.graphics, named: backupName)
            return
        }
        guard let size = rdarCanvasSize() else {
            rdar_fix_enabled = false
            return
        }

        try backupSystemFileIfNeeded(at: TweakPaths.graphics, named: backupName)
        let dictionary = try loadSystemPlist(at: TweakPaths.graphics)
        dictionary["canvas_width"] = size.width
        dictionary["canvas_height"] = size.height
        try writeSystemPlist(dictionary, to: TweakPaths.graphics)
        print("(rdar) applied canvas size \(size.width)x\(size.height)")
    }

    private func applyLockScreenFootnote() throws {
        let backupName = "SharedDeviceConfiguration.plist"
        let backupExists = FileManager.default.fileExists(atPath: systemBackupURL(named: backupName).path)
        guard lockscreen_footnote_enabled || backupExists else { return }
        try grantSystemPathAccess(TweakPaths.lockScreenConfiguration)

        guard lockscreen_footnote_enabled else {
            _ = try restoreSystemFileIfBackedUp(at: TweakPaths.lockScreenConfiguration, named: backupName)
            return
        }

        try backupSystemFileIfNeeded(at: TweakPaths.lockScreenConfiguration, named: backupName)
        let dictionary = try loadSystemPlist(at: TweakPaths.lockScreenConfiguration)
        dictionary["LockScreenFootnote"] = lockscreen_footnote
        try writeSystemPlist(dictionary, to: TweakPaths.lockScreenConfiguration)
        print("(lockscreen) applied custom footnote")
    }

    private func restoreAllSystemTweaks() throws {
        let graphicsBackup = "IOMobileGraphicsFamily.plist"
        if FileManager.default.fileExists(atPath: systemBackupURL(named: graphicsBackup).path) {
            try grantSystemPathAccess(TweakPaths.graphics)
            _ = try restoreSystemFileIfBackedUp(at: TweakPaths.graphics, named: graphicsBackup)
        }

        let footnoteBackup = "SharedDeviceConfiguration.plist"
        if FileManager.default.fileExists(atPath: systemBackupURL(named: footnoteBackup).path) {
            try grantSystemPathAccess(TweakPaths.lockScreenConfiguration)
            _ = try restoreSystemFileIfBackedUp(at: TweakPaths.lockScreenConfiguration, named: footnoteBackup)
        }
    }

    private func mg_write(_ data: Data) throws {
        let target_url = URL(fileURLWithPath: TweakPaths.gestalt)
        let temp_url = target_url.deletingLastPathComponent()
            .appendingPathComponent(".\(target_url.lastPathComponent).\(UUID().uuidString).tmp")

        try data.write(to: temp_url, options: [.withoutOverwriting])
        defer { try? fm.removeItem(at: temp_url) }

        if fm.fileExists(atPath: target_url.path) {
            _ = try fm.replaceItemAt(target_url, withItemAt: temp_url)
        } else {
            try fm.moveItem(at: temp_url, to: target_url)
        }
    }
    
    private func mg_key_binding<T: Equatable>(_ keys: [String], type: T.Type = Int.self, default_val: T? = 0, on_val: T? = 1) -> Binding<Bool>  {
        guard let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary else {
            return .constant(false)
        }
        
        return Binding(get: {
            if let value = cache_extra[keys.first!] as? T?, let on_val {
                return value == on_val
            }
            
            return false
        }, set: { enabled in
            for key in keys {
                // if it exists inside of the plist, then update it. if not then pull the value completely.
                if enabled {
                    cache_extra[key] = on_val
                } else {
                    cache_extra.removeObject(forKey: key)
                }
            }
        })
    }
    
    private func mg_trollpad_binding() -> Binding<Bool> {
        guard let cache_data = mg_dict_now["CacheData"] as? NSMutableData,
                let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary else {
            return .constant(false)
        }
        
        let value_off = cache_data_offset("mtrAoWJ3gsq+I90ZnQ0vQw")
        let keys = [
            "uKc7FPnEO++lVhHWHFlGbQ", // ipad
            "mG0AnH/Vy1veoqoLRAIgTA", // MedusaFloatingLiveAppCapability
            "UCG5MkVahJxG1YULbbd5Bg", // MedusaOverlayAppCapability
            "ZYqko/XM5zD3XBfN5RmaXA", // MedusaPinnedAppCapability
            "nVh/gwNpy7Jv1NOk00CMrw", // MedusaPIPCapability,
            "qeaj75wk3HF4DwQ8qbIi7g", // DeviceSupportsEnhancedMultitasking
        ]
        
        return Binding(get: {
            if let value = cache_extra[keys.first!] as? Int? {
                return value == 1
            }
            
            return false
        }, set: { enabled in
            if enabled {
                Alertinator.shared.alert(title: "警告！", body: "这是一项非常危险的修改！如果你使用字母数字密码，请绝对不要启用。请勿关闭“在台前调度中显示程序坞”，否则设备旋转到横屏时可能无限重启。启用后仍可能出现系统不稳定、App 数据意外丢失或缩放异常等问题，请自行承担风险。")
            }
            
            cache_data.mutableBytes.storeBytes(of: enabled ? 3 : 1, toByteOffset: value_off, as: Int.self)
            
            for key in keys {
                if enabled {
                    cache_extra[key] = 1
                } else {
                    cache_extra.removeObject(forKey: key)
                }
            }
        })
    }
    
    private func mg_region_restrict_binding() -> Binding<Bool> {
        guard let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary else {
            return .constant(false)
        }
        
        return Binding<Bool>(
            get: {
                return cache_extra["h63QSdBCiT/z0WU6rdQv6Q"] as? String == "US" &&
                    cache_extra["zHeENZu+wbg7PUprwNwBWg"] as? String == "LL/A"
            },
            set: { enabled in
                if enabled {
                    Alertinator.shared.alert(title: "警告！", body: "请勿使用此功能绕过当地法律规定的地区限制（例如关闭相机快门声）。任何违法使用行为及其后果均由使用者自行承担。")
                    cache_extra["h63QSdBCiT/z0WU6rdQv6Q"] = "US"
                    cache_extra["zHeENZu+wbg7PUprwNwBWg"] = "LL/A"
                } else {
                    cache_extra.removeObject(forKey: "h63QSdBCiT/z0WU6rdQv6Q")
                    cache_extra.removeObject(forKey: "zHeENZu+wbg7PUprwNwBWg")
                }
            }
        )
    }
    
    private func mg_internal_binding() -> Binding<Bool> {
        guard let cache_data = mg_dict_now["CacheData"] as? NSMutableData else {
            return .constant(false)
        }
        
        let off_apple_internal_install = cache_data_offset("EqrsVvjcYDdxHBiQmGhAWw")
        let off_has_internal_settings_bundle = cache_data_offset("Oji6HRoPi7rH7HPdWVakuw")
        let off_internal_build = cache_data_offset("LBJfwOEzExRxzlAnSuI7eg")
        
        return Binding(
            get: {
                return cache_data.bytes.load(fromByteOffset: off_apple_internal_install, as: Int.self) == 1
            },
            set: { enabled in
                cache_data.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_apple_internal_install, as: Int.self)
                cache_data.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_has_internal_settings_bundle, as: Int.self)
                cache_data.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_internal_build, as: Int.self)
            }
        )
    }
    
    private func is_device_good() -> Bool {
        let supported: [String] = ["iPhone15,2", "iPhone15,3", "iPhone15,4", "iPhone15,5", "iPhone16,1", "iPhone16,2", "iPhone17,3", "iPhone17,4", "iPhone17,1", "iPhone17,2", "iPhone18,3", "iPhone18,1", "iPhone18,2", "iPhone17,5"]
        
        if supported.contains(machine_name()) && doubleSystemVersion() < 19.0 {
            return true
        }
        
        return false
    }
    
    private func machine_name() -> String {
        var sys_info = utsname()
        uname(&sys_info)
        let machine_mirror = Mirror(reflecting: sys_info.machine)
        
        return machine_mirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
}
