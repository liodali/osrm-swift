// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "osrm-swift",
    platforms: [.macOS(.v10_13),
                 .iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "osrm-swift",
            targets: ["osrm-swift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.9.1")),
        .package(url: "https://github.com/raphaelmor/Polyline.git", from: "5.0.2"),
        //.package(url: "https://github.com/WeTransfer/Mocker.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/JohnSundell/Files.git", from: "4.2.0"),
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs.git", .upToNextMajor(from: "9.1.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "osrm-swift",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "Polyline", package: "Polyline"),
                
            ],
            resources: [
                .process("resources/en.json"),
                .process("resources/es.json"),
                .process("resources/ar.json"),
                .process("resources/de.json"),
            ]),
        .testTarget(
            name: "osrm-swiftTests",
            dependencies: [
                "osrm-swift",
                //"Mocker",
                "Files",
                .product(name: "OHHTTPStubs", package: "OHHTTPStubs"),
                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs")
            ],
            resources: [.process("res_tests/example1.json")]),
        
    ]
)
