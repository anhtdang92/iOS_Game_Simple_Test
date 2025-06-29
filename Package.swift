// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ArcaneAnvil",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .executable(
            name: "ArcaneAnvil",
            targets: ["ArcaneAnvil"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ArcaneAnvil",
            path: "Sources/ArcaneAnvil"
        )
    ]
) 