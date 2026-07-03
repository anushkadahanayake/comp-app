import Foundation

struct TriviaService {
    private let urlString = "https://opentdb.com/api.php?amount=10&type=multiple"
    
    func fetchQuestions() async throws -> [TriviaQuestion] {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(TriviaResponse.self, from: data)
        
        guard decoded.response_code == 0 else {
            throw NSError(
                domain: "TriviaService",
                code: decoded.response_code,
                userInfo: [NSLocalizedDescriptionKey: "Trivia API returned error code \(decoded.response_code)"]
            )
        }
        
        return decoded.results
    }
}
