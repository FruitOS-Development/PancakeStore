import SwiftUI

struct AppResult: Identifiable, Decodable {
    let id: Int
    let trackName: String
    let artworkUrl100: String
    let sellerName: String
    let averageUserRating: Double?
    let primaryGenreName: String
    
    enum CodingKeys: String, CodingKey {
        case id = "trackId"
        case trackName, artworkUrl100, sellerName, averageUserRating, primaryGenreName
    }
}

struct AppStoreSearchView: View {
    @State private var searchText = ""
    @State private var results = [AppResult]()
    @State private var selectedApp: AppResult?
    let ipaTool: IPATool
    
    var body: some View {
        NavigationStack {
            List(results) { app in
                HStack(spacing: 15) {
                    AsyncImage(url: URL(string: app.artworkUrl100)) { image in
                        image.resizable()
                    } placeholder: {
                        Color(white: 0.2)
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.trackName)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(app.sellerName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button("Laden") {
                        selectedApp = app
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                }
                .listRowBackground(Color.black)
                .listRowSeparatorTint(Color.gray.opacity(0.3))
            }
            .background(Color.black)
            .scrollContentBackground(.hidden)
            .navigationTitle("Suche")
            .searchable(text: $searchText, prompt: "Apps durchsuchen...")
            .onChange(of: searchText) { newValue in
                performSearch(query: newValue)
            }
            .sheet(item: $selectedApp) { app in
                AppDetailView(appId: String(app.id), ipaTool: ipaTool)
            }
        }
    }
    
    private func performSearch(query: String) {
        guard !query.isEmpty else { self.results = []; return }
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://itunes.apple.com/search?term=\(encodedQuery)&country=de&entity=software"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            if let decoded = try? JSONDecoder().decode(SearchResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.results = decoded.results
                }
            }
        }.resume()
    }
}

struct SearchResponse: Decodable {
    let results: [AppResult]
}
