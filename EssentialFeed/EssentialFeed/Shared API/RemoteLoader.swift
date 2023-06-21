import Foundation

public final class RemoteLoader<Resource> {
    private var url: URL
    private var client: HTTPClient
    private let mapper: Mapper
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias Result = Swift.Result<Resource, Swift.Error>
    
    public typealias Mapper = (Data, HTTPURLResponse) throws -> Resource
    
    public init(url: URL, client: HTTPClient, mapper: @escaping Mapper) {
        self.client = client
        self.url = url
        self.mapper = mapper
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .success((data, response)):
                completion(self.map(data, from: response))
                
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
    
    private func map(_ data: Data, from response: HTTPURLResponse) -> Result {
        if let items = try? mapper(data, response) {
            return .success(items)
        } else {
            return .failure(Error.invalidData)
        }
    }
}
