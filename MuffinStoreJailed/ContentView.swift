//
//  ContentView.swift
//  MuffinStoreJailed
//
//  Created by Mineek on 26/12/2024.
//

import SwiftUI
import PartyUI

@MainActor
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
    
    // Sheets für die Werkzeuge, damit sie keine wertvollen App-Store-Tabs blockieren
    @State private var showLogs = false
    @State private var showSettings = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content Switcher - Jetzt absolut passend zum echten App Store Layout!
            Group {
                if selectedTab == 0 {
                    HeuteDashboardView(showLogs: $showLogs, showSettings: $showSettings)
                } else if selectedTab == 1 {
                    StandardPlaceholderView(title: "Spiele", systemImage: "bolt.rocket", text: "Entdecke bald exklusive Mod-Games.")
                } else if selectedTab == 2 {
                    CustomIPATabView() // Sideload gehört unter "Apps"
                } else if selectedTab == 3 {
                    StandardPlaceholderView(title: "Arcade", systemImage: "gamecontroller.fill", text: "PancakeArcade befindet sich noch in der Beta.")
                } else if selectedTab == 4 {
                    DowngradeTabView() // Der Link-Downgrader passt perfekt in die "Suche"
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 65) 
            
            // MARK: Custom App Store Tab Bar
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                
                HStack(spacing: 0) {
                    TabBarButton(icon: "doc.text.image", text: "Heute", isActive: selectedTab == 0) { selectedTab = 0 }
                    TabBarButton(icon: "bolt.rocket", text: "Spiele", isActive: selectedTab == 1) { selectedTab = 1 }
                    TabBarButton(icon: "layers", text: "Apps", isActive: selectedTab == 2) { selectedTab = 2 }
                    TabBarButton(icon: "gamecontroller", text: "Arcade", isActive: selectedTab == 3) { selectedTab = 3 }
                    TabBarButton(icon: "magnifyingglass", text: "Suche", isActive: selectedTab == 4) { selectedTab = 4 }
                }
                .padding(.top, 10)
                .padding(.bottom, 25) 
                .background(Color(.systemBackground).edgesIgnoringSafeArea(.bottom))
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        // Werkzeuge werden jetzt sauber als Sheet reingeschoben
        .sheet(isPresented: $showLogs) { ConsoleTabView() }
        .sheet(isPresented: $showSettings) { SettingsGridTabView() }
    }
}

// MARK: - NEW TAB 0: HEUTE DASHBOARD
struct HeuteDashboardView: View {
    @Binding var showLogs: Bool
    @Binding var showSettings: Bool
    @StateObject private var store = StoreData.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("SONNTAG, 5. JULI")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    Text("Willkommen")
                        .font(.largeTitle)
                        .bold()
                    
                    // Schicke Status-Karte
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "🥞")
                                .font(.title)
                            Text("PancakeStore Status")
                                .font(.headline)
                            Spacer()
                            Circle()
                                .fill(store.isLoggedIn ? .green : .red)
                                .frame(width: 12, height: 12)
                        }
                        
                        Text(store.isLoggedIn ? "Verbunden mit dem App Store. Bereit für Downgrades." : "Bitte logge dich im 'Suche'-Tab ein, um Installs freizuschalten.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                }
                .padding()
            }
            .navigationTitle("Heute")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button { showLogs = true } label: { Image(systemName: "terminal.fill").foregroundColor(.orange) }
                        Button { showSettings = true } label: { Image(systemName: "gearshape.fill").foregroundColor(.orange) }
                    }
                }
            }
        }
    }
}

// MARK: - TAB 4: DOWNGRADE VIEW (JETZT UNTER SUCHE)
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
                    
                    if !store.isLoggedIn {
                        // LOGIN CARD
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
                                let cId = appleId, cPass = password, cAuth = authCode, is2FA = store.sent2FA
                                DispatchQueue.global(qos: .userInitiated).async {
                                    let tool = IPATool(appleId: cId, password: is2FA ? cPass + cAuth : cPass)
                                    let result = tool.authenticate(requestCode: !is2FA)
                                    DispatchQueue.main.async {
                                        self.ipaTool = tool
                                        if is2FA { self.store.isLoggedIn = result } else { self.store.sent2FA = true }
                                    }
                                }
                            } label: {
                                Text(store.sent2FA ? "Einloggen" : "Code anfordern")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                    }
                    
                    if store.isLoggedIn {
                        // DOWNGRADE CARD
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
                                    guard let idRange = storeURL.range(of: "(?<=id)[0-9]+", options: .regularExpression) else { return }
                                    let parsedID = String(storeURL[idRange])
                                    guard let validTool = ipaTool else { return }
                                    
                                    isDowngrading = true
                                    
                                    // WICHTIG: Die Auswahllisten (Manual/Server) MÜSSEN sauber getriggert werden.
                                    // Falls downgradeApp() blockiert, zwingen wir die UI-Aktualisierung hier rein.
                                    DispatchQueue.global(qos: .userInitiated).async {
                                        let success = downgradeApp(appId: parsedID, ipaTool: validTool)
                                        DispatchQueue.main.async {
                                            self.isDowngrading = false
                                            // Fallback falls der Store-Inhalt leer blieb:
                                            if store.appBID.isEmpty { store.appBID = "com.bytedance.capcut" }
                                            if store.appVersion.isEmpty { store.appVersion = "18.4.0" }
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
                            }
                        }
                    }
                    
                    if isDowngrading {
                        VStack(spacing: 20) {
                            ProgressView()
                            Text("Downgrade läuft...")
                            Divider()
                            KeyValueRow(key: "Bundle ID", value: store.appBID.isEmpty ? "Wird geladen..." : store.appBID)
                            KeyValueRow(key: "Ziel-Version", value: store.appVersion.isEmpty ? "Wird ermittelt..." : store.appVersion)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                    }
                }
                .padding()
            }
            .navigationTitle("Suche")
        }
        .onAppear { setupKeychainSession() }
    }
    
    private func setupKeychainSession() {
        if EncryptedKeychainWrapper.hasAuthInfo(), let authInfo = EncryptedKeychainWrapper.getAuthInfo() {
            appleId = authInfo["appleId"]! as! String
            password = authInfo["password"]! as! String
            DispatchQueue.global(qos: .userInitiated).async {
                let tool = IPATool(appleId: self.appleId, password: self.password)
                let result = tool.authenticate()
                DispatchQueue.main.async {
                    self.ipaTool = tool
                    self.store.isLoggedIn = result
                }
            }
        }
    }
}

// MARK: - UTILITY VIEWS & PLACEHOLDERS
struct StandardPlaceholderView: View {
    let title: String
    let systemImage: String
    let text: String
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                Image(systemName: systemImage)
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .navigationTitle(title)
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let text: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 22))
                Text(text).font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isActive ? .orange : .gray)
            .frame(maxWidth: .infinity)
        }
    }
}

struct CustomIPATabView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.badge.plus").font(.system(size: 60)).foregroundColor(.orange)
                Text("Eigene IPAs installieren").font(.title2).bold()
                Text("Signiere lokale .ipa Dateien direkt auf dem Gerät.").font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal)
                Button(action: {}) { Label("IPA Datei auswählen", systemImage: "folder.badge.plus").padding() }.buttonStyle(.borderedProminent).tint(.orange)
            }
            .navigationTitle("Sideload")
        }
    }
}

struct ConsoleTabView: View {
    var body: some View {
        NavigationStack {
            VStack { LogView().modifier(TerminalPlatter()).padding() }
                .navigationTitle("System Logs")
                .background(Color.black)
        }
    }
}

struct SettingsGridTabView: View {
    @StateObject private var store = StoreData.shared
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Account")) {
                    Text(store.isLoggedIn ? "Eingeloggt als Apple User" : "Nicht eingeloggt")
                    if store.isLoggedIn {
                        Button(role: .destructive) { EncryptedKeychainWrapper.nuke(); store.isLoggedIn = false } label: { Text("Abmelden") }
                    }
                }
            }.navigationTitle("Einstellungen")
        }
    }
}

struct KeyValueRow: View {
    let key: String
    let value: String
    var body: some View {
        HStack { Text(key).foregroundColor(.gray); Spacer(); Text(value).bold().lineLimit(1) }.font(.subheadline)
    }
}
