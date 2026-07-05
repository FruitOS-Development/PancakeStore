import SwiftUI
import UniformTypeIdentifiers

struct AppDetailView: View {
    let appId: String
    let ipaTool: IPATool
    
    @Environment(\.dismiss) private var dismiss
    @State private var showFileImporter = false
    @State private var showFileExporter = false
    @State private var exportURL: URL?
    @State private var showManualURLAlert = false
    @State private var manualURLText = ""
    
    var body: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .padding(10)
                        .background(Color(white: 0.15))
                        .clipShape(Circle())
                        .foregroundColor(.blue)
                }
                Spacer()
                
                Menu {
                    Button(action: { showManualURLAlert = true }) {
                        Label("Manuelle App Store URL", systemImage: "link")
                    }
                    Button(action: { showFileImporter = true }) {
                        Label("Externe IPA importieren", systemImage: "doc.badge.plus")
                    }
                    Button(action: { prepareIPAForExport() }) {
                        Label("Geladene IPA exportieren", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 16) {
                        Color(white: 0.15).frame(width: 100, height: 100).cornerRadius(22)
                            .overlay(Image(systemName: "app.badge").font(.largeTitle).foregroundColor(.gray))
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Google Gemini")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Google")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                _ = downgradeApp(appId: appId, ipaTool: ipaTool)
                            }) {
                                Text("LADEN")
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            .padding(.top, 5)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    HStack {
                        VStack(spacing: 4) {
                            Text("202.565 BEWERTUNGEN").font(.system(size: 9)).foregroundColor(.gray)
                            Text("4,6").font(.title3).fontWeight(.bold).foregroundColor(.gray)
                            Text("★★★★★").font(.caption).foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider().background(Color.gray.opacity(0.3)).frame(height: 40)
                        
                        VStack(spacing: 4) {
                            Text("ALTERSFREIGABE").font(.system(size: 9)).foregroundColor(.gray)
                            Text("13+").font(.title3).fontWeight(.bold).foregroundColor(.gray)
                            Text("Jahre").font(.caption).foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider().background(Color.gray.opacity(0.3)).frame(height: 40)
                        
                        VStack(spacing: 4) {
                            Text("CHART").font(.system(size: 9)).foregroundColor(.gray)
                            Text("#3").font(.title3).fontWeight(.bold).foregroundColor(.blue)
                            Text("Produktivität").font(.caption).foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 5)
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Auch enthalten in")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        HStack {
                            Color(white: 0.15).frame(width: 50, height: 50).cornerRadius(10)
                            VStack(alignment: .leading) {
                                Text("Das Beste von Google").foregroundColor(.white).font(.headline)
                                Text("Produktivität").foregroundColor(.gray).font(.subheadline)
                            }
                            Spacer()
                            Button("Anzeigen") {}.buttonStyle(.bordered).tint(.blue)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [UTType(filenameExtension: "ipa")!]) { result in
            if case .success(let url) = result {
                print("Importiertes File: \(url.path)")
            }
        }
        .fileExporter(isPresented: $showFileExporter, document: TransparentIPADocument(url: exportURL), contentType: UTType(filenameExtension: "ipa")!) { _ in }
        .alert("Manuelle URL", isPresented: $showManualURLAlert) {
            TextField("App Store URL", text: $manualURLText)
            Button("Downgrade") {
                if let id = manualURLText.components(separatedBy: "/id").last?.components(separatedBy: "?").first {
                    _ = downgradeApp(appId: id, ipaTool: ipaTool)
                }
            }
            Button("Abbrechen", role: .cancel) {}
        }
    }
    
    private func prepareIPAForExport() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let potentialIPA = docs.appendingPathComponent("app/app.ipa")
        if FileManager.default.fileExists(atPath: potentialIPA.path) {
            self.exportURL = potentialIPA
            self.showFileExporter = true
        }
    }
}

struct TransparentIPADocument: FileDocument {
    static var readableContentTypes: [UTType] { [UTType(filenameExtension: "ipa")!] }
    var fileURL: URL?
    init(url: URL?) { self.fileURL = url }
    init(configuration: ReadConfiguration) throws {}
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url = fileURL else { throw CocoaError(.fileNoSuchFile) }
        return try FileWrapper(url: url)
    }
}
