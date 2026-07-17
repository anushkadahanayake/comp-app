import Foundation

enum TriviaServiceError: LocalizedError {
    case badURL
    case rateLimited
    case noResults(categoryId: Int?)
    case invalidParameter
    case server(statusCode: Int)
    case api(code: Int)
    case decoding

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "Invalid trivia request."
        case .rateLimited:
            return "Trivia server is busy (rate limit). Wait a few seconds and try again."
        case .noResults:
            return "Not enough questions in this category. Try another category or Any."
        case .invalidParameter:
            return "Invalid category filter. Try another category."
        case .server(let code):
            return "Trivia server error (\(code)). Please try again."
        case .api(let code):
            return "Trivia API error (code \(code)). Please try again."
        case .decoding:
            return "Could not read trivia questions. Please try again."
        }
    }
}

struct TriviaService {
    /// Open Trivia DB — category + difficulty filters are optional.
    func fetchQuestions(
        categoryId: Int? = nil,
        difficulty: String? = nil,
        amount: Int = 10
    ) async throws -> [Question] {
        var lastError: Error = TriviaServiceError.rateLimited

        for attempt in 0..<3 {
            if attempt > 0 {
                try await Task.sleep(nanoseconds: UInt64(attempt) * 1_500_000_000)
            }

            do {
                return try await performFetch(
                    categoryId: categoryId,
                    difficulty: difficulty,
                    amount: amount
                )
            } catch TriviaServiceError.rateLimited {
                lastError = TriviaServiceError.rateLimited
                continue
            } catch TriviaServiceError.noResults {
                // Soften filter until we get something playable.
                if difficulty != nil {
                    return try await fetchQuestions(
                        categoryId: categoryId,
                        difficulty: nil,
                        amount: amount
                    )
                }
                if categoryId != nil {
                    if amount > 5 {
                        return try await fetchQuestions(
                            categoryId: categoryId,
                            difficulty: nil,
                            amount: 5
                        )
                    }
                    return try await performFetch(
                        categoryId: nil,
                        difficulty: nil,
                        amount: amount
                    )
                }
                throw TriviaServiceError.noResults(categoryId: categoryId)
            } catch {
                throw error
            }
        }

        throw lastError
    }

    private func performFetch(
        categoryId: Int?,
        difficulty: String?,
        amount: Int
    ) async throws -> [Question] {
        var components = URLComponents(string: "https://opentdb.com/api.php")
        var items: [URLQueryItem] = [
            URLQueryItem(name: "amount", value: String(amount)),
            URLQueryItem(name: "type", value: "multiple")
        ]
        if let categoryId {
            items.append(URLQueryItem(name: "category", value: String(categoryId)))
        }
        if let difficulty {
            items.append(URLQueryItem(name: "difficulty", value: difficulty))
        }
        components?.queryItems = items

        guard let url = components?.url else {
            throw TriviaServiceError.badURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TriviaServiceError.server(statusCode: -1)
        }

        if httpResponse.statusCode == 429 {
            throw TriviaServiceError.rateLimited
        }

        guard httpResponse.statusCode == 200 else {
            throw TriviaServiceError.server(statusCode: httpResponse.statusCode)
        }

        let decoded: TriviaResponse
        do {
            decoded = try JSONDecoder().decode(TriviaResponse.self, from: data)
        } catch {
            throw TriviaServiceError.decoding
        }

        switch decoded.response_code {
        case 0:
            guard !decoded.results.isEmpty else {
                throw TriviaServiceError.noResults(categoryId: categoryId)
            }
            return decoded.results
        case 1:
            throw TriviaServiceError.noResults(categoryId: categoryId)
        case 2:
            throw TriviaServiceError.invalidParameter
        case 5:
            throw TriviaServiceError.rateLimited
        default:
            throw TriviaServiceError.api(code: decoded.response_code)
        }
    }
}
