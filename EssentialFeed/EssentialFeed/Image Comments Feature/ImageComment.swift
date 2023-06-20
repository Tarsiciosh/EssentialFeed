import Foundation

public struct ImageComment: Equatable {
    let id: UUID
    let message: String
    let createdAt: Date
    let username: String
    
    public init(id: UUID, message: String, createdAt: Date, username: String) {
        self.id = id
        self.message = message
        self.createdAt = createdAt
        self.username = username
    }
}
