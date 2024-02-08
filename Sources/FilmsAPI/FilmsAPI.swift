// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import FilmsModel
import Alamofire

// MARK: - Constants
public enum APIKey {
    static public let key = "c7ead67bdd4b4fbb6b19fee66be8c9dd"
}

public enum URLs {
    static public let baseURL = "https://api.themoviedb.org/3/"
    static public let imageBaseURL = "https://image.tmdb.org/t/p/original"
}

public enum Requests {
    static public let popular = "movie/popular"
    static public let nowPlaying = "movie/now_playing"
    static public let upcoming = "movie/upcoming"
    static public let topRated = "movie/top_rated"
    static public let movieDetails = "movie/"
    static public let castAndCrew = "movie/"
    static public let genres = "genre/movie/list"
    static public let moviesOfTheGenre = "discover/movie"
}


public protocol NetworkManagerProtocol: AnyObject {
    func getPopular() async throws -> Popular?
    func getNowPlaying() async throws -> NowPlaying?
    func getUpcoming() async throws -> Upcoming?
    func getTopRated() async throws -> TopRated?
    func getGenres() async throws -> Genres?
    func getMoviesOfTheGenre(id: Int, page: Int) async throws -> MoviesOfGenre?
    func getMovieDetails(id: Int) async throws -> MovieDetails?
    func getCastAndCrew(id: Int) async throws -> CastAndCrew?
}

public final class NetworkManager: NetworkManagerProtocol {

    // MARK: - Variable
    public let baseURL = URL(string: URLs.baseURL)
    public let apiKey = APIKey.key

    public var session: Session = {
        let configuration = URLSessionConfiguration.af.default
        configuration.timeoutIntervalForRequest = 30
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        return Session(configuration: configuration)
    }()


    public init(session: Session) {
        self.session = session
    }


    // MARK: - Network layer
    public func fetchData<T: Decodable>(request: String) async throws -> T? {
        guard let url = baseURL else { return nil }
        let endpoint: URL?
        let apiKey = URLQueryItem(name: "api_key", value: APIKey.key)
        endpoint = url
            .appendingPathComponent(request)
            .appending(queryItems: [apiKey])

        return try await withCheckedThrowingContinuation { continuation in
            guard let endpoint = endpoint else { return }

            session.request(endpoint.absoluteString, method: .get).validate().responseDecodable(of: T.self) { response in
                if let result = response.value {
                    continuation.resume(returning: result)
                }

                if let error = response.error {
                    debugPrint(error.localizedDescription)
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func fetchGenresData<T: Decodable>(request: String, forGenreId: String, forPage: String) async throws -> T? {
        guard let url = baseURL else { return nil }
        var endpoint: URL?
        let apiKey = URLQueryItem(name: "api_key", value: APIKey.key)
        let genreItems = URLQueryItem(name: "with_genres", value: forGenreId)
        let pageId = URLQueryItem(name: "page", value: forPage)
        endpoint = url
            .appendingPathComponent(request)
            .appending(queryItems: [apiKey, genreItems, pageId])

        return try await withCheckedThrowingContinuation { continuation in
            guard let endpoint = endpoint else { return }

            session.request(endpoint.absoluteString, method: .get).validate().responseDecodable(of: T.self) { response in
                if let result = response.value {
                    continuation.resume(returning: result)
                }

                if let error = response.error {
                    debugPrint(error.localizedDescription)
                    continuation.resume(throwing: error)
                }
            }
        }
    }


    // MARK: - Protocol Implemetation
    public func getPopular() async throws -> Popular? {
        let request = Requests.popular
        let data: Popular? = try await fetchData(request: request)
        return data
    }

    public func getNowPlaying() async throws -> NowPlaying? {
        let request = Requests.nowPlaying
        let data: NowPlaying? = try await fetchData(request: request)
        return data
    }

    public func getUpcoming() async throws -> Upcoming? {
        let request = Requests.upcoming
        let data: Upcoming? = try await fetchData(request: request)
        return data
    }

    public func getTopRated() async throws -> TopRated? {
        let request = Requests.topRated
        let data: TopRated? = try await fetchData(request: request)
        return data
    }

    public func getGenres() async throws -> Genres? {
        let request = Requests.genres
        let data: Genres? = try await fetchData(request: request)
        return data
    }

    public func getMoviesOfTheGenre(id: Int, page: Int) async throws -> MoviesOfGenre? {
        let forGenreId = "\(id)"
        let pageId = "\(page)"
        let request = Requests.moviesOfTheGenre
        let data: MoviesOfGenre? = try await fetchGenresData(request: request, forGenreId: forGenreId, forPage: pageId)
        return data
    }

    public func getMovieDetails(id: Int) async throws -> MovieDetails? {
        let movieId = "\(id)"
        let request = Requests.movieDetails + movieId
        let data: MovieDetails? = try await fetchData(request: request)
        return data
    }

    public func getCastAndCrew(id: Int) async throws -> CastAndCrew? {
        let movieId = "\(id)/credits"
        let request = Requests.castAndCrew + movieId
        let data: CastAndCrew? = try await fetchData(request: request)
        return data
    }
}
