//
//  ContentView.swift
//  revenueSegmentation
//
//  Created by Sanzhi Kobzhan on 20.09.2024.
//
import SwiftUI
import Charts

struct ProductSegment: Identifiable {
    let id = UUID()
    let category: String
    let value: Double
}

class RevenueViewModel: ObservableObject {
    @Published var productSegments: [ProductSegment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchRevenueData(for symbol: String) {
        let apiKey = ""
        let apiUrl = "https://financialmodelingprep.com/api/v4/revenue-product-segmentation?symbol=\(symbol)&structure=flat&period=annual&apikey=\(apiKey)"
        
        guard let url = URL(string: apiUrl) else { return }
        
        self.isLoading = true
        self.errorMessage = nil
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch data: \(error?.localizedDescription ?? "Unknown error")"
                }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: [String: Double]]]
                DispatchQueue.main.async {
                    self.productSegments = self.parseJson(json: json ?? [])
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode JSON: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    private func parseJson(json: [[String: [String: Double]]]) -> [ProductSegment] {
        var parsedData: [ProductSegment] = []

        if let latestYearData = json.first?.values.first {
            for (category, value) in latestYearData {
                let segment = ProductSegment(category: category, value: value)
                parsedData.append(segment)
            }
        }
        
        return parsedData
    }
}

struct ContentView: View {
    @ObservedObject var viewModel = RevenueViewModel()
    @State private var ticker: String = "AAPL"
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter ticker symbol", text: $ticker)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Fetch Data") {
                    viewModel.fetchRevenueData(for: ticker.uppercased())
                }
                .padding()
                
                if viewModel.isLoading {
                    ProgressView()
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else if !viewModel.productSegments.isEmpty {
                   
                    PieChartView(productSegments: viewModel.productSegments)
                        .frame(height: 300)
                        .padding()

                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(viewModel.productSegments) { segment in
                                HStack {
                                    Text(segment.category)
                                        .font(.body)
                                        .bold()
                                    
                                    Spacer()
                                    
                                    Text(String(format: "$%.2f", segment.value))
                                        .font(.body)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 5)
                                Divider()
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 200)
                } else {
                    Text("Please enter stock ticker and press the Fetch Data button")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Revenue Segmentation")
        }
    }
}

struct PieChartView: View {
    var productSegments: [ProductSegment]
    
    var body: some View {
        let largestSegment = productSegments.max(by: { $0.value < $1.value })
        
        Chart {
            ForEach(productSegments) { segment in
                SectorMark(
                    angle: .value("Revenue", segment.value),
                    innerRadius: .ratio(0.5),
           
                    outerRadius: .ratio(largestSegment?.id == segment.id ? 1.2 : 1.0)
                )
                .foregroundStyle(by: .value("Category", segment.category))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
