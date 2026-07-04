//
//  SettingsView.swift
//  PancakeStore
//
//  Created by lunginspector on 1/11/26.
//

import SwiftUI
import PartyUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    @AppStorage("autoCleanApp") var autoCleanApp: Bool = true
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        AppInfoCell(build: "Release")
                        HStack {
                            Button {
                                openURL(URL(string: "https://jailbreak.party/discord")!)
                            } label: {
                                ButtonLabel(text: "Discord", icon: "discord", useImage: true)
                            }
                            .buttonStyle(TranslucentButtonStyle(color: .discord))
                            
                            Button {
                                openURL(URL(string: "https://github.com/jailbreakdotparty/PancakeStore")!)
                            } label: {
                                ButtonLabel(text: "GitHub", icon: "github", useImage: true)
                            }
                            .buttonStyle(TranslucentButtonStyle(color: .github))
                        }
                        
                        Button {
                            openURL(URL(string: "https://jailbreak.party/")!)
                        } label: {
                            ButtonLabel(text: "Website", icon: "globe")
                        }
                        .buttonStyle(TranslucentButtonStyle())
                    }
                } header: {
                    HeaderLabel(text: "About", icon: "info.circle")
                }
                
                Section {
                    Toggle(isOn: $autoCleanApp) {
                        Text("Auto-Clean App")
                        Text("This is toggled on by default to make sure that PancakeStore doesn't keep any saved data from the app you had downgraded.")
                    }
                    
                    Button("Clean Documents") {
                        cleanUp()
                    }
                } header: {
                    HeaderLabel(text: "Data", icon: "loupe")
                }
                
                Section {
                    LinkCreditCell(image: Image("mineek"), name: "mineek", description: "Original creator of MuffinStore Jailed.", url: "https://github.com/mineek")
                    LinkCreditCell(image: Image("lunginspector"), name: "lunginspector", description: "Obiliterated the frontend multiple times. Also did some backend fixes.", url: "https://github.com/lunginspector")
                    LinkCreditCell(image: Image("skadz"), name: "Skadz", description: "Fixed the entire authentication system thrice.", url: "https://github.com/skadz108")
                } header: {
                    HeaderLabel(text: "Credits", icon: "star")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}
