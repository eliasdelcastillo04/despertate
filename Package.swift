// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Alarma",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AlarmaCore",
            targets: ["AlarmaCore"]
        ),
        .executable(
            name: "AlarmaApp",
            targets: ["Alarma"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AlarmaCore",
            dependencies: [],
            path: "Sources/AlarmaCore"
        ),
        .executableTarget(
            name: "Alarma",
            dependencies: ["AlarmaCore"],
            path: "Sources/Alarma",
            exclude: ["Info.plist"],
            resources: [
                .process("Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "AlarmaTests",
            dependencies: ["AlarmaCore"],
            path: "Tests/AlarmaTests"
        ),
        .testTarget(
            name: "AlarmaE2ETests",
            dependencies: ["AlarmaCore"],
            path: "Tests/AlarmaE2ETests"
        )
    ]
)
