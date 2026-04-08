// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Parlay",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit", from: "0.9.0"),
    ],
    targets: [
        .executableTarget(
            name: "Parlay",
            dependencies: ["WhisperKit"],
            path: "Parlay",
            exclude: ["Resources/AppInfo.plist", "Resources/Parlay.entitlements"]
        ),
    ]
)
