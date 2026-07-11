// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MacStayAwake",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacStayAwake", targets: ["MacStayAwake"])
    ],
    targets: [
        .executableTarget(
            name: "MacStayAwake",
            linkerSettings: [
                .linkedFramework("IOKit")
            ]
        ),
        .testTarget(
            name: "MacStayAwakeTests",
            dependencies: ["MacStayAwake"]
        )
    ]
)
