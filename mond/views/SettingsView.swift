//
//  SettingsView.swift
//  mond
//
//  Created by ruter on 18.07.26.
//

import SwiftUI
import PartyUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var state: AppState
    
    @AppStorage("token") private var token: String = ""
    @AppStorage("method") private var method: String = "bad_query"
    @State private var show_confirm: Bool = false
    
    var valid: Bool {
        (sandbox_extension_consume(token) ?? -1) >= 0
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        if let url = URL(string: "https://github.com/Github1145142882/mond-zh"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
                               let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
                               let files = primary["CFBundleIconFiles"] as? [String],
                               let icon = files.last,
                               let img = UIImage(named: icon) {
                                Image(uiImage: img)
                                    .resizable()
                                    .frame(width: 45, height: 45)
                                    .cornerRadius(12)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                                     ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
                                     ?? "未知 App")
                                .font(.headline)
                                
                                Text("\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .fontWeight(.semibold)
                                .foregroundStyle(.tertiary)
                                .imageScale(.small)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Section {
                    LogView()
                        .modifier(TerminalPlatter())
                } header: {
                    Label("日志", systemImage: "apple.terminal")
                }
                
                Section {
                    HStack {
                        TextField("沙盒扩展令牌", text: $token)
                        
                        Spacer()
                        
                        Button {
                            UIPasteboard.general.string = token
                        } label: {
                            Image(systemName: "document.on.document")
                        }
                    }
                    .contextMenu {
                        Text("类别：\(token.split(separator: ";").first { $0.contains("com.apple") }.map(String.init) ?? "不可用")")
                        Text("路径：\(token.split(separator: ";").last.map(String.init) ?? "不可用")")
                        
                        Button {
                            UIPasteboard.general.string = token
                        } label: {
                            Label("复制令牌", systemImage: "doc.on.doc")
                        }
                    }
                    .lineLimit(1)
                    
                    Button {
                        token = sandbox_extension_issue_file(path: TweakPaths.gestalt_dir) ?? "获取令牌失败。"
                    } label: {
                        Text("生成令牌")
                    }
                    .disabled(!state.exploit_succeeded)
                } header: {
                    Label("令牌", systemImage: "key")
                } footer: {
                    if !token.isEmpty && token != "获取令牌失败。" {
                        if valid {
                            Text("沙盒令牌有效。")
                        } else {
                            Text("沙盒令牌无效。")
                        }
                    }
                    
                    if !state.exploit_succeeded {
                        Text("漏洞利用失败，因此已停用。请确认当前 iOS 版本是否受支持。")
                    }
                }
                
                Section {
                    Picker("方法", selection: $method) {
                        Text("bad_query").tag("bad_query")
                        Text("cmg").tag("cmg")
                    }
                    .pickerStyle(.segmented)
                    
                    Button {
                        _ = grant_mg_write()
                    } label: {
                        Text("运行漏洞利用")
                    }
                } header: {
                    Label("漏洞利用", systemImage: "wrench.and.screwdriver")
                } footer: {
                    Text(method == "cmg" ? "**CMG：** 支持 iOS 27.0 beta 1 至 beta 4，建议优先使用 bad_query。" : "**bad_query：** 支持 iOS 27.0 beta 1 至 beta 4，由 [forcequit](https://github.com/forcequitOS) 开发。")
                }
                
                Section {
                    Button {
                        show_confirm = true
                    } label: {
                        Text("重载桌面")
                    }
                } header: {
                    Label("工具", systemImage: "wrench.and.screwdriver")
                }
                
                Section {
                    CreditsRow(name: "roooot", role: "主要开发者", profile: URL(string: "https://github.com/rooootdev")!)
                    CreditsRow(name: "forcequit", role: "bad_query 漏洞利用", profile: URL(string: "https://github.com/forcequitOS")!)
                    CreditsRow(name: "johnny", role: "MCM 漏洞类相关工作", profile: URL(string: "https://github.com/0xjohnnydev")!)
                    CreditsRow(name: "jailbreak.party", role: "PartyUI, GestaltView", profile: URL(string: "https://github.com/jailbreakdotparty")!)
                } header: {
                    Label("致谢", systemImage: "person.3.fill")
                }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Text("完成")
                        }
                    }
                }
            }
            .alert("确定要继续吗？", isPresented: $show_confirm) {
                Button("取消") {
                    show_confirm = false
                }
                
                Button("确认") {
                    state.respring()
                }
            } message: {
                Text("确认要重载桌面。")
            }
        }
    }
}

struct CreditsRow: View {
    let name: String
    let role: String
    let profile: URL

    private var pfp: URL? {
        URL(string: profile.absoluteString + ".png")
    }

    var body: some View {
        HStack(alignment: .top) {
            AsyncImage(url: pfp) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)

                Text(role)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .onTapGesture {
            UIApplication.shared.open(profile)
        }
    }
}
