// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "KampanyaRadar",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .executable(name: "KampanyaRadar", targets: ["KampanyaRadar"]),
    ],
    targets: [
        .executableTarget(
            name: "KampanyaRadar",
            path: "Sources/KampanyaRadar"
        ),
    ]
)
