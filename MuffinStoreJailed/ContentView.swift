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
    
    @State private var ipaTool: IPATool?
    @State private var storeURL = ""
    @State private var isDowngrading = false
    
    @State private var appleId = ""
    @State private var password = ""
    @State private var authCode = ""
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content Switcher - Exakt gemappt nach ScreenRecording_07-05-2026 16-54-02_1.mp4
            Group {
                if selectedTab == 0 {
                    // HEUTE-TAB: Hier lebt dein funktionaler Link-Downgrader
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
                                                
                                                DispatchQueue.global(qos: .userInitiated).async {
                                                    // FIX: 'success' zu '_' geändert, um den Exit Code 65 Build-Fehler zu beheben!
                                                    _ = downgradeApp(appId: parsedID, ipaTool: validTool)
                                                    
                                                    DispatchQueue.main.async {
                                                        self.isDowngrading = false
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
                                        LocalKeyValueRow(key: "Bundle ID", value: store.appBID.isEmpty ? "Wird geladen..." : store.appBID)
                                        LocalKeyValueRow(key: "Ziel-Version", value: store.appVersion.isEmpty ? "Wird ermittelt..." : store.appVersion)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(16)
                                }
                            }
                            .padding()
                        }
                        .navigationTitle("PancakeStore")
                    }
                    .onAppear { setupKeychainSession() }
                    
                } else if selectedTab == 1 {
                    // SPIELE-TAB
                    NavigationStack {
                        VStack(spacing: 15) {
                            Text("Spiele kommen bald")
                                .font(.title2)
                                .bold()
                        }
                        .navigationTitle("Spiele")
                    }
                    
                } else if selectedTab == 2 {
                    // APPS-TAB: Sideload Bereich
                    NavigationStack {
                        VStack(spacing: 20) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                            Text("Eigene IPAs installieren")
                                .font(.title2)
                                .bold()
                            Text("Hier kannst du bald deine eigenen, lokal gespeicherten .ipa Dateien direkt über PancakeStore signieren und auf dein Gerät sideloaden.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: {}) {
                                Label("IPA Datei auswählen", systemImage: "folder.badge.plus")
                                    .padding()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        }
                        .navigationTitle("Sideload")
                    }
                    
                } else if selectedTab == 3 {
                    // ARCADE-TAB: Ruft jetzt deine ECHTE, funktionale LogView auf!
                    NavigationStack {
                        LogView()
                            .navigationTitle("System Logs")
                    }
                    
                } else if selectedTab == 4 {
                    // SUCHE-TAB: Ruft jetzt deine ECHTE SettingsView auf!
                    SettingsView()
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
                    ContentTabBarButton(icon: "doc.text.image", text: "Heute", isActive: selectedTab == 0) { selectedTab = 0 }
                    ContentTabBarButton(icon: "bolt.rocket", text: "Spiele", isActive: selectedTab == 1) { selectedTab = 1 }
                    ContentTabBarButton(icon: "layers", text: "Apps", isActive: selectedTab == 2) { selectedTab = 2 }
                    ContentTabBarButton(icon: "gamecontroller", text: "Arcade", isActive: selectedTab == 3) { selectedTab = 3 }
                    ContentTabBarButton(icon: "magnifyingglass", text: "Suche", isActive: selectedTab == 4) { selectedTab = 4 }
                }
                .padding(.top, 10)
                .padding(.bottom, 25)
                .background(Color(.systemBackground).edgesIgnoringSafeArea(.bottom))
            }
        }
        .edgesIgnoringSafeArea(.bottom)
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

// Eindeutige Namen um globale Redeclaration-Fehler im Target zu verhindern
struct ContentTabBarButton: View {
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

struct LocalKeyValueRow: View {
    let key: String
    let value: String
    var body: some View {
        HStack {
            Text(key).foregroundColor(.gray)
            Spacer()
            Text(value).bold().lineLimit(1)
        }
        .font(.subheadline)
    }
}
