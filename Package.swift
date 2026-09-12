// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AsisLogic",
    platforms: [.macOS(.v13)],
    products: [.library(name: "AsisLogic", targets: ["AsisLogic"])],
    targets: [
        .target(name: "AsisLogic", path: "Asis/Domain"),
        .testTarget(name: "AsisLogicTests", dependencies: ["AsisLogic"], path: "Tests/AsisLogicTests")
    ]
)
