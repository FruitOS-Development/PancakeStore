import SwiftUI

struct TodayView: View {
    let ipaTool: IPATool
    @State private var showDetailView = false
    @State private var selectedAppId = "6472043444" // Google Gemini ID
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 25) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("SONNTAG, 5. JULI")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            Text("Heute")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Circle()
                            .fill(Color(white: 0.2))
                            .frame(width: 36, height: 36)
                            .overlay(Image(systemName: "person.crop.circle").foregroundColor(.white))
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading) {
                        ZStack(alignment: .bottomLeading) {
                            LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .top, endPoint: .bottom)
                                .frame(height: 350)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PRODUKTIVITÄT")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("KI-Power auf deinem Legacy-Device")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .padding(.bottom, 75)
                        }
                        
                        HStack(spacing: 12) {
                            Color.white.opacity(0.2)
                                .frame(width: 45, height: 45)
                                .cornerRadius(10)
                                .overlay(Image(systemName: "sparkles").foregroundColor(.white))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Google Gemini")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Erlebe die Zukunft.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button("Laden") {
                                selectedAppId = "6472043444"
                                showDetailView = true
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                            .tint(.white.opacity(0.2))
                        }
                        .padding()
                        .background(Color(white: 0.1))
                    }
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .shadow(radius: 10)
                    .onTapGesture {
                        selectedAppId = "6472043444"
                        showDetailView = true
                    }
                }
                .padding(.bottom, 100)
            }
            .background(Color.black)
            .sheet(isPresented: $showDetailView) {
                AppDetailView(appId: selectedAppId, ipaTool: ipaTool)
            }
        }
    }
}
