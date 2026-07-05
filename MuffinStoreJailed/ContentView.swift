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
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DowngradeTabView()
                .tabItem {
                    Label("Downgrade", systemImage: "arrow.down.app.fill")
                }
                .tag(0)
            
            CustomIPATabView()
                .tabItem {
                    Label("Eigene IPAs", systemImage: "doc.badge.plus")
                }
                .tag(1)
            
            ConsoleTabView()
                .tabItem {
                    Label("Logs", systemImage: "terminal.fill")
                }
                .tag(2)
            
            SettingsGridTabView()
                .tabItem {
                    Label("Einstellungen", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.orange) // PancakeStore Branding-Farbe
    }
}

// MARK: - TAB 1: DOWNGRADE VIEW (APP STORE STYLE)
struct DowngradeTabView: View {
    @StateObject private var store = StoreData.shared
    @State private var ipaTool: IPATool?
    @State private var storeURL = ""
    @State private var isDowngrading = false
    
    @State private var appleId = ""
    @State private var password = ""
    @State private var authCode = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // LOGIN CARD (Wenn nicht eingeloggt)
                    if !store.isLoggedIn {
                        VStack(spacing: 15) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.key.fill")
                                    .font(.title)
                                    .foregroundStyle(.orange)
                                Text("App Store Login")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            TextField("Apple ID", text: $appleId)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                            
                            SecureField("Passwort", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                            
                            if store.sent2FA {
                                TextField("2FA Bestätigungscode", text: $authCode)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)
                            }
                            
                            Button {
                                if store.sent2FA {
                                    let finalPassword = password + authCode
                                    ipaTool = IPATool(appleId: appleId, password: finalPassword)
                                    let _ = ipaTool?.authenticate()
                                } else {
                                    ipaTool = IPATool(appleId: appleId, password: password)
                                    let _ = ipaTool?.authenticate(requestCode: true)
                                }
                            } label: {
                                Text(store.sent2FA ? "Einloggen" : "Code anfordern")
                                    .font(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            .disabled(appleId.isEmpty || password.isEmpty)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // DOWNGRADE CARD (Wenn eingeloggt)
                    if store.isLoggedIn {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Downgrade per Link")
                                .font(.title3)
                                .bold()
                            
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.gray)
                                TextField("App Store URL hier einfügen...", text: $storeURL)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            
                            if !isDowngrading {
                                Button {
                                    // CRASH FIX 1: Sicherer RegEx-Parser für die ID
                                    guard let idRange = storeURL.range(of: "(?<=id)[0-9]+", options: .regularExpression) else {
                                        print("[!] URL ungültig.")
                                        return
                                    }
                                    let parsedID = String(storeURL[idRange])
                                    
                                    // CRASH FIX 2: Absicherung gegen Nil-Instanzen
                                    guard let validTool = ipaTool else { return }
                                    
                                    isDowngrading = true
                                    
                                    // CRASH FIX 3: Komplett asynchroner Thread (Verhindert iOS-Watchdog-Kill!)
                                    DispatchQueue.global(qos: .userInitiated).async {
                                        let success = downgradeApp(appId: parsedID, ipaTool: validTool)
                                        
                                        DispatchQueue.main.async {
                                            self.isDowngrading = success
                                        }
                                    }
                                } label: {
                                    Label("App jetzt downgraden", systemImage: "arrow.down.circle.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                                .disabled(storeURL.isEmpty)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // STATUS & PRODUKT KARTE (Während / Nach dem Downgrade)
                    if isDowngrading {
                        VStack(spacing: 20) {
                            if store.hasServedApp {
                                VStack(spacing: 8) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 60))
                                        .foregroundStyle(.green)
                                    Text("Erfolgreich downgegraded!")
                                        .font(.headline)
                                    
                                    Button {
                                        LSApplicationWorkspace.default().openApplication(withBundleID: store.appBID)
                                    } label: {
                                        Label("App öffnen", systemImage: "arrow.up.right.square")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                    .padding(.top, 10)
                                }
                            } else {
                                HStack(spacing: 15) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                    VStack(alignment: .leading) {
                                        Text("Downgrade läuft...")
                                            .font(.headline)
                                        Text("Bitte die App nicht schließen.")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                            }
                            
                            Divider()
                            
                            // App Info Grid
                            VStack(spacing: 12) {
                                KeyValueRow(key: "Bundle ID", value: store.appBID.isEmpty ? "Wird geladen..." : store.appBID)
                                KeyValueRow(key: "Ziel-Version", value: store.appVersion.isEmpty ? "Wird ermittelt..." : store.appVersion)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("PancakeStore")
        }
        .onAppear {
            setupKeychainSession()
        }
    }
    
    private func setupKeychainSession() {
        store.isLoggedIn = EncryptedKeychainWrapper.hasAuthInfo()
        if store.isLoggedIn {
            guard let authInfo = EncryptedKeychainWrapper.getAuthInfo() else {
                store.isLoggedIn = false
                return
            }
            appleId = authInfo["appleId"]! as! String
            password = authInfo["password"]! as! String
            ipaTool = IPATool(appleId: appleId, password: password)
            let result = ipaTool?.authenticate() ?? false
            store.isLoggedIn = result
        }
    }
}

// MARK: - TAB 2: EIGENE IPAS (FUTURE FEATURE WORK)
struct CustomIPATabView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                Text("Eigene IPAs installieren")
                    .font(.title2)
                    .bold()
                
                Text("Hier kannst du bald deine eigenen, lokal gespeicherten .ipa Dateien direkt über PancakeStore signieren und auf dein Gerät sideloaden.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                Button(action: {}) {
                    Label("IPA Datei auswählen", systemImage: "folder.badge.plus")
                        .font(.headline)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .navigationTitle("Sideload")
        }
    }
}

// MARK: - TAB 3: CONSOLE VIEW (AUSGELAGERT)
struct ConsoleTabView: View {
    var body: some View {
        NavigationStack {
            VStack {
                LogView()
                    .modifier(TerminalPlatter())
                    .padding()
            }
            .navigationTitle("System Logs")
            .background(Color(.black))
        }
    }
}

// MARK: - TAB 4: SETTINGS
struct SettingsGridTabView: View {
    @StateObject private var store = StoreData.shared
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Account")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.orange)
                        Text(store.isLoggedIn ? "Eingeloggt als Apple User" : "Nicht eingeloggt")
                    }
                    
                    if store.isLoggedIn {
                        Button(role: .destructive) {
                            EncryptedKeychainWrapper.nuke()
                            EncryptedKeychainWrapper.generateAndStoreKey()
                            store.isLoggedIn = false
                        } label: {
                            Text("Abmelden")
                        }
                    }
                }
                
                Section(header: Text("Werkzeuge")) {
                    Button {
                        LSApplicationWorkspace().openApplication(withBundleID: "com.apple.AppStore")
                    } label: {
                        Label("Offiziellen App Store öffnen", systemImage: "bag")
                    }
                }
            }
            .navigationTitle("Einstellungen")
        }
    }
}

// MARK: - HELPER VIEWS
struct KeyValueRow: View {
    let key: String
    let value: String
    
    var body: some View {
        HStack {
            Text(key)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .bold()
                .lineLimit(1)
        }
        .font(.subheadline)
    }
}
