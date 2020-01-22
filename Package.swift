// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Haneke",
    platforms: [.iOS("8.0"), .tvOS("9.1")],
    products: [.library(name: "Haneke", targets: ["Haneke"])],
    targets: [.target(name: "Haneke", path: "Haneke")]
)
