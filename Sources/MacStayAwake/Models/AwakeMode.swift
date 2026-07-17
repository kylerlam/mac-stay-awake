enum AwakeMode: Equatable {
    case normal
    case awake
    case mismatch(expectedAwake: Bool, actualAwake: Bool)
    case unknown
}
