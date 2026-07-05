import SwiftUI
import UniformTypeIdentifiers

enum DownloadPhase: String {
    case idle = ""
    case downloading = "Lade IPA von Apple Servern..."
    case unpacking = "Entpacke Payload..."
    case signing = "Signiere App-Zertifikate..."
    case serving = "Bereite lokalen Server vor..."
    case completed = "Fertig! Installation startet..."
}

class DownloadManager: ObservableObject {
    static let shared = DownloadManager()
    
    @Published var currentPhase: DownloadPhase = .idle
    @Published var progress: Double = 0.0
    @Published var estimatedTimeRemaining: String = ""
    @Published var showOverlay: Bool = false
    
    private var startTime: Date?
    
    func startTracking(phase: DownloadPhase) {
        DispatchQueue.main.async {
            self.currentPhase = phase
            self.progress = 0.0
            self.startTime = Date()
            self.showOverlay = true
        }
    }
    
    func updateProgress(_ currentBytes: Double, totalBytes: Double) {
        DispatchQueue.main.async {
            guard totalBytes > 0 else { return }
            self.progress = currentBytes / totalBytes
            
            guard let startTime = self.startTime else { return }
            let elapsed = Date().timeIntervalSince(startTime)
            if self.progress > 0 {
                let totalTime = elapsed / self.progress
                let remaining = totalTime - elapsed
                if remaining > 0 {
                    self.estimatedTimeRemaining = String(format: "Noch ca. %.0f Sek.", remaining)
                }
            }
        }
    }
    
    func updatePhase(_ phase: DownloadPhase) {
        DispatchQueue.main.async {
            self.currentPhase = phase
            if phase == .completed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.showOverlay = false
                    self.currentPhase = .idle
                }
            }
        }
    }
}
