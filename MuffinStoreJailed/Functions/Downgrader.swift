//
//  Downgrader.swift
//  MuffinStoreJailed
//
//  Created by Mineek on 19/10/2024.
//

import Foundation
import UIKit
import Telegraph
import Zip
import SwiftUI
import SafariServices
import PartyUI

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

func downgradeAppToVersion(appId: String, versionId: String, ipaTool: IPATool) {
    @ObservedObject var data = StoreData.shared
    
    DownloadManager.shared.startTracking(phase: .downloading)
    
    let path = ipaTool.downloadIPAForVersion(appId: appId, appVerId: versionId)
    print("IPA downloaded to \(path)")
    
    DownloadManager.shared.updatePhase(.unpacking)
    
    let tempDir = FileManager.default.temporaryDirectory
    let contents = try! FileManager.default.contentsOfDirectory(atPath: path)
    let destinationUrl = tempDir.appendingPathComponent("app.ipa")
    try! Zip.zipFiles(paths: contents.map { URL(fileURLWithPath: path).appendingPathComponent($0) }, zipFilePath: destinationUrl, password: nil, progress: { progress in
        DownloadManager.shared.updateProgress(progress, totalBytes: 1.0)
    })
    
    var path2 = URL(fileURLWithPath: path)
    var appDir = path2.appendingPathComponent("Payload")
    for file in try! FileManager.default.contentsOfDirectory(atPath: appDir.path) {
        if file.hasSuffix(".app") {
            appDir = appDir.appendingPathComponent(file)
            break
        }
    }
    let infoPlistPath = appDir.appendingPathComponent("Info.plist")
    let infoPlist = NSDictionary(contentsOf: infoPlistPath)!
    let appBundleId = infoPlist["CFBundleIdentifier"] as! String
    let appVersion = infoPlist["CFBundleShortVersionString"] as! String

    data.appBID = appBundleId
    data.appVersion = appVersion
    
    DownloadManager.shared.updatePhase(.signing)
    
    let finalURL = "https://api.palera.in/genPlist?bundleid=\(appBundleId)&name=\(appBundleId)&version=\(appVersion)&fetchurl=http://127.0.0.1:9090/signed.ipa"
    let installURL = "itms-services://?action=download-manifest&url=" + finalURL.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
    
    DownloadManager.shared.updatePhase(.serving)
    
    DispatchQueue.global(qos: .background).async {
        let server = Server()
        server.route(.GET, "signed.ipa", { _ in
            let signedIPAData = try Data(contentsOf: destinationUrl)
            return HTTPResponse(body: signedIPAData)
        })
        server.route(.GET, "install", { _ in
            data.hasServedApp = true
            let installPage = "<script type=\"text/javascript\">window.location = \"\(installURL)\"</script>"
            return HTTPResponse(.ok, headers: ["Content-Type": "text/html"], content: installPage)
        })
        
        try! server.start(port: 9090)
        
        DispatchQueue.main.async {
            DownloadManager.shared.updatePhase(.completed)
            let safariView = SafariWebView(url: URL(string: "http://127.0.0.1:9090/install")!)
            UIApplication.shared.windows.first?.rootViewController?.present(UIHostingController(rootView: safariView), animated: true, completion: nil)
        }
        
        while server.isRunning { sleep(1) }
    }
}

func promptForVersionId(appId: String, versionIds: [String], ipaTool: IPATool) {
    let isiPad = UIDevice.current.userInterfaceIdiom == .pad
    let alert = UIAlertController(title: "Enter version ID", message: "Select a version to downgrade to", preferredStyle: isiPad ? .alert : .actionSheet)
    for versionId in versionIds {
        alert.addAction(UIAlertAction(title: versionId, style: .default, handler: { _ in
            downgradeAppToVersion(appId: appId, versionId: versionId, ipaTool: ipaTool)
        }))
    }
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    
    if let popover = alert.popoverPresentationController, let root = UIApplication.shared.windows.first?.rootViewController {
        popover.sourceView = root.view
        popover.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
        popover.permittedArrowDirections = []
    }
    UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
}

func showAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
}

func getAllAppVersionIdsFromServer(appId: String, ipaTool: IPATool) {
    let serverURL = "https://apis.bilin.eu.org/history/\(appId)"
    guard let url = URL(string: serverURL) else { return }
    
    URLSession.shared.dataTask(with: URLRequest(url: url)) { data, _, error in
        if let error = error {
            DispatchQueue.main.async { showAlert(title: "Error", message: error.localizedDescription) }
            return
        }
        let json = try! JSONSerialization.jsonObject(with: data!) as! [String: Any]
        let versionIds = json["data"] as! [Dictionary<String, Any>]
        if versionIds.count == 0 {
            DispatchQueue.main.async { showAlert(title: "Error", message: "No version IDs found.") }
            return
        }
        DispatchQueue.main.async {
            let isiPad = UIDevice.current.userInterfaceIdiom == .pad
            let alert = UIAlertController(title: "Select a version", message: "Select a version to downgrade to", preferredStyle: isiPad ? .alert : .actionSheet)
            for versionId in versionIds {
                alert.addAction(UIAlertAction(title: "\(versionId["bundle_version"]!)", style: .default, handler: { _ in
                    downgradeAppToVersion(appId: appId, versionId: "\(versionId["external_identifier"]!)", ipaTool: ipaTool)
                }))
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            if let popover = alert.popoverPresentationController, let root = UIApplication.shared.windows.first?.rootViewController {
                popover.sourceView = root.view
                popover.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }.resume()
}

func downgradeApp(appId: String, ipaTool: IPATool) -> Bool {
    let versionIds = ipaTool.getVersionIDList(appId: appId)
    if versionIds.isEmpty {
        print("No version ids were found, aborting...")
        DispatchQueue.main.async {
            Alertinator.shared.alert(title: "Failed to downgrade app!", body: "Failed to get available version ids.")
        }
        return false
    }
    
    DispatchQueue.main.async {
        let isiPad = UIDevice.current.userInterfaceIdiom == .pad
        let alert = UIAlertController(title: "Version ID", message: "Manual or Server identifier collection?", preferredStyle: isiPad ? .alert : .actionSheet)
        alert.addAction(UIAlertAction(title: "Manual", style: .default, handler: { _ in
            promptForVersionId(appId: appId, versionIds: versionIds, ipaTool: ipaTool)
        }))
        alert.addAction(UIAlertAction(title: "Server", style: .default, handler: { _ in
            getAllAppVersionIdsFromServer(appId: appId, ipaTool: ipaTool)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let popoverController = alert.popoverPresentationController, let rootVC = UIApplication.shared.windows.first?.rootViewController {
            popoverController.sourceView = rootVC.view
            popoverController.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    return true
}

func cleanUp() {
    do {
        let tempDir = FileManager.default.temporaryDirectory
        try FileManager.default.removeItem(at: tempDir.appendingPathComponent("app.ipa"))
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        try FileManager.default.removeItem(at: docsURL.appendingPathComponent("app"))
    } catch {}
}
