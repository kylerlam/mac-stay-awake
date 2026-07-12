protocol AwakeService: AnyObject {
    var isActive: Bool { get }

    func activate() throws
    func deactivate() throws
}

enum AwakeServiceError: Error, Equatable {
    case assertionCreationFailed(Int32)
    case assertionReleaseFailed(Int32)
    case commandFailed(Int32)
}
