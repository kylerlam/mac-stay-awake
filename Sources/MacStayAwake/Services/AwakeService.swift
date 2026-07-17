protocol AwakeService: AnyObject {
    var isActive: Bool { get }

    func currentStatus() throws -> Bool
    func activate() throws
    func deactivate() throws
}

enum AwakeServiceError: Error, Equatable {
    case commandFailed(Int32)
    case statusUnavailable
}
