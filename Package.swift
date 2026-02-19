// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LangLens",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit", from: "0.9.0"),
    ],
    targets: [
        .executableTarget(
            name: "LangLens",
            dependencies: ["WhisperKit"],
            path: "LangLens",
            exclude: ["Resources/AppInfo.plist", "Resources/LangLens.entitlements"]
        ),
    ]
)
