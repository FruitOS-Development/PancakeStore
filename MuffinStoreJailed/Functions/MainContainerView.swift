import SwiftUI

struct MainContainerView: View {
    @State private var selectedTab = 0
    @ObservedObject var downloadManager = DownloadManager.shared
    let ipaTool: IPATool
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            Group {
                switch selectedTab {
                case 0: TodayView(ipaTool: ipaTool)
                case 4: AppStoreSearchView(ipaTool: ipaTool)
                default: 
                    VStack {
                        Text("In Kürze verfügbar")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                }
            }
            
            VStack {
                Spacer()
                HStack(spacing: 25) {
                    TabBarButton(icon: "doc.text.image", text: "Heute", isActive: selectedTab == 0) { selectedTab = 0 }
                    TabBarButton(icon: "bolt.rocket", text: "Spiele", isActive: selectedTab == 1) { selectedTab = 1 }
                    TabBarButton(icon: "layers", text: "Apps", isActive: selectedTab == 2) { selectedTab = 2 }
                    TabBarButton(icon: "gamecontroller", text: "Arcade", isActive: selectedTab == 3) { selectedTab = 3 }
                    TabBarButton(icon: "magnifyingglass", text: "Suche", isActive: selectedTab == 4) { selectedTab = 4 }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .cornerRadius(30)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                .padding(.bottom, 15)
            }
            
            if downloadManager.showOverlay {
                DownloadOverlayView()
            }
        }
    }
}
