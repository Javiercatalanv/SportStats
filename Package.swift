// swift-tools-version: 6.0
// Manifiesto para compilar con xtool (Windows/Linux). En Mac se sigue usando SportStats.xcodeproj.

import PackageDescription

let package = Package(
    name: "SportStats",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        // xtool espera exactamente una librería: la app.
        .library(
            name: "SportStats",
            targets: ["SportStats"]
        ),
    ],
    targets: [
        .target(
            name: "SportStats",
            path: ".",
            exclude: ["Frontend/Assets.xcassets"],
            sources: ["Frontend", "Backend"],
            // El proyecto Xcode compila en modo Swift 5.
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
