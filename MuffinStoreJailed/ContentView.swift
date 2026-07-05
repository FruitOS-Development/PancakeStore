//
//  ContentView.swift
//  MuffinStoreJailed
//
//  Created by Mineek on 26/12/2024.
//

import SwiftUI
import PartyUI

final class StoreData: ObservableObject {
    static let shared = StoreData()
    
    @Published var appBID = ""
    @Published var appVersion = ""
    @Published var hasServedApp = false
    @Published var sent2FA = false
    @Published var isLoggedIn = false
}

struct ContentView: View {
    @StateObject private var store = StoreData.shared
    @State private var ipaTool: IPATool?
    
    @State private var appleId = ""
    @State private var password = ""
    @State private var authCode = ""
    
    @State private var storeURL = ""
    @State private var isDowngrading = false
    
    @State private var shownWelcome = false
    @State private var showSettings = false
    
    let device = UIDevice.current
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    LogView()
                        .modifier(TerminalPlatter())
                } header: {
                    HeaderLabel(text: "Logs", icon: "terminal")
                } footer: {
                    Text("Made with love by the [jailbreak.party](https://jailbreak.party) team.\n[Join the jailbreak.party Discord!](https://jailbreak.party/discord)")
                }
                
                // login stuff
                if !store.isLoggedIn {
                    Section {
                        TextField("Apple ID", text: $appleId)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        SecureField("Password", text: $password)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    } header: {
                        HeaderLabel(text: "Log In", icon: "cloud")
                    }
                    
                    if store.sent2FA {
                        Section {
                            TextField("2FA Code", text: $authCode)
                                .keyboardType(.numberPad)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } header: {
                            HeaderLabel(text: "Authentication", icon: "faceid")
                        }
                    }
                }
                
                // on login
                if store.isLoggedIn && !isDowngrading {
                    Section {
                        TextField("App Store URL", text: $storeURL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    } header: {
                        HeaderLabel(text: "Downgrade App", icon: "arrow.down.app")
                    } footer: {
                        Text("Not all apps are eligible for downgrading. Make sure that you've purchased the app in the App Store and that it is not currently installed before continuing.")
                    }
                }
                
                // while downgrading
                if isDowngrading {
                    Section {
                        if store.hasServedApp {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Downgraded Application!")
                            }
                        } else {
                            HStack(spacing: 12) {
                                ProgressView()
                                Text("Downgrading Application...")
                            }
                        }
                    }
                    
                    Section {
                        LabeledContent("App Store URL") {
                            if storeURL.isEmpty {
                                ProgressView()
                            } else {
                                Text(storeURL)
                                    .contextMenu {
                                        Button {
                                            UIPasteboard.general.string = storeURL
                                        } label: {
                                            Label("Copy", systemImage: "doc.on.doc")
                                        }
                                    }
                            }
                        }
                        
                        LabeledContent("Bundle ID") {
                            if store.appBID.isEmpty {
                                ProgressView()
                            } else {
                                Text(store.appBID)
                                    .contextMenu {
                                        Button {
                                            UIPasteboard.general.string = store.appBID
                                        } label: {
                                            Label("Copy", systemImage: "doc.on.doc")
                                        }
                                    }
                            }
                        }
                        
                        LabeledContent("Version") {
                            if store.appVersion.isEmpty {
                                ProgressView()
                            } else {
                                Text(store.appVersion)
                            }
                        }
                    } header: {
                        HeaderLabel(text: "App Info", icon: "info.circle")
                    }
                }
            }
            .navigationTitle("PancakeStore")
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                Group {
                    if !store.isLoggedIn && !store.sent2FA {
                        Button {
                            ipaTool = IPATool(appleId: appleId, password: password)
                            let _ = ipaTool?.authenticate(requestCode: true)
                        } label: {
                            ButtonLabel(text: "Continue", icon: "arrow.right")
                        }
                        .buttonStyle(FancyButtonStyle())
                        .disabled(appleId.isEmpty || password.isEmpty)
                    }
                    
                    if !store.isLoggedIn && store.sent2FA {
                        Button {
                            let finalPassword = password + authCode
                            ipaTool = IPATool(appleId: appleId, password: finalPassword)
                            let _ = ipaTool?.authenticate()
                        } label: {
                            ButtonLabel(text: "Log In", icon: "arrow.right")
                        }
                        .buttonStyle(FancyButtonStyle())
                        .disabled(authCode.isEmpty)
                    }
                    
                    if store.isLoggedIn && !isDowngrading {
                        Button {
                            // Safe RegEx pattern searching for numeric sequence directly following "id"
                            guard let idRange = storeURL.range(of: "(?<=id)[0-9]+", options: .regularExpression) else {
                                print("[!] Error parsing URL: Could not extract numeric App ID.")
                                return
                            }
                            let appLinkParsed = String(storeURL[idRange])
                            print("App ID: \(appLinkParsed)")
                            
                            // Prevent explicit unwrapping runtime crashes
                            guard let validTool = ipaTool else {
                                print("[!] Critical Error: Active IPATool session instance is missing.")
                                return
                            }
                            
                            isDowngrading = true
                            
                            // Run the operation asynchronously on a background queue to preserve UI responsiveness
                            DispatchQueue.global(qos: .userInitiated).async {
                                let success = downgradeApp(appId: appLinkParsed, ipaTool: validTool)
                                
                                // Safely return to the UI main thread to reflect final progress
                                DispatchQueue.main.async {
                                    self.isDowngrading = success
                                }
                            }
                        } label: {
                            ButtonLabel(text: "Downgrade App", icon: "arrow.down")
                        }
                        .buttonStyle(FancyButtonStyle())
                        .disabled(storeURL.isEmpty)
                    }
                    
                    if isDowngrading {
                        VStack {
                            Button {
                                LSApplicationWorkspace.default().openApplication(withBundleID: store.appBID)
                            } label: {
                                ButtonLabel(text: "Open App", icon: "arrow.up.right.square")
                            }
                            .buttonStyle(FancyButtonStyle())
                            .disabled(!store.hasServedApp)
                        }
                    }
                }
                .modifier(OverlayBackground())
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            LSApplicationWorkspace().openApplication(withBundleID: "com.apple.AppStore")
                        } label: {
                            Label("Open App Store", systemImage: "bag")
                        }
                        
                        Button(role: .destructive) {
                            Alertinator.shared.alert(title: "Are you sure you'd like to do this?", body: "You'll have to sign back in again to use PancakeStore.", actionLabel: "Sign out", action: {
                                EncryptedKeychainWrapper.nuke()
                                EncryptedKeychainWrapper.generateAndStoreKey()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    exitinator()
                                }
                            })
                        } label: {
                            Label("Sign Out", systemImage: "person.fill.xmark")
                        }
                        .disabled(!store.isLoggedIn)
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings.toggle()
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                print("\n=== PancakeStore v\(AppInfo.appVersion) (Release) ===")
                store.isLoggedIn = EncryptedKeychainWrapper.hasAuthInfo()
                print("Found \(store.isLoggedIn ? "auth" : "no auth") info in keychain")
                
                if store.isLoggedIn {
                    guard let authInfo = EncryptedKeychainWrapper.getAuthInfo() else {
                        print("Failed to get auth info from keychain, logging out")
                        store.isLoggedIn = false
                        EncryptedKeychainWrapper.nuke()
                        EncryptedKeychainWrapper.generateAndStoreKey()
                        return
                    }
                    
                    appleId = authInfo["appleId"]! as! String
                    password = authInfo["password"]! as! String
                    
                    ipaTool = IPATool(appleId: appleId, password: password)
                    let result = ipaTool?.authenticate() ?? false
                    
                    // Fixed: Bind login UI structure directly to the remote confirmation value
                    store.isLoggedIn = result
                    print("Re-authenticated \(result ? "successfully" : "unsuccessfully")")
                } else {
                    print("No auth info found in keychain, setting up by generating a key in SEP")
                    EncryptedKeychainWrapper.generateAndStoreKey()
                }
                
                print("[*] Welcome to PancakeStore! Running on \(device.systemName) \(device.systemVersion), \(machineName()).")
                
                if !store.isLoggedIn {
                    print("[!] Logging in may break at random due to Apple's constant server-side changes. If login fails, make sure that you're on the latest version of PancakeStore.")
                } else {
                    print("[*] Copy an app store link into the field below to downgrade. Do NOT ask for support if a specific app can't be downgraded or crashes on launch. There is nothing we can do about this.")
                }
            }
            .onOpenURL { schemedURL in
                let rawURL = schemedURL.absoluteString.replacingOccurrences(of: "pancakestore:", with: "")
                if let appLink = rawURL.removingPercentEncoding {
                    storeURL = appLink
                    print("Successfully received app link! \(appLink)")
                }
            }
        }
    }
}

func machineName() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    return machineMirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
    }
}

#Preview {
    ContentView()
}
