// swift-tools-version:5.7.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let optCSettings = ["-Os"]
let optimizeC = [CSetting.unsafeFlags(optCSettings)]
let optimize:[SwiftSetting] = []//[SwiftSetting.unsafeFlags(["-cross-module-optimization", "-Ounchecked", "-g", "-debug-info-format=dwarf", "-remove-runtime-asserts", "-enforce-exclusivity=unchecked"])]

let package = Package(
    name: "GameEngine",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "GameEngineLib",
            type: .static,
            targets: ["GameEngine"]),
        .executable(name: "ParticleTweenTest", targets: ["ParticleTest"])
    ],
    dependencies: [
        .package(url: "https://github.com/izackp/SDL.git", branch: "master"),
        .package(url: "https://github.com/eonil/FSEvents.git", from:"0.1.7"),
        .package(url: "https://github.com/izackp/icu-swift.git", branch: "master"),
        .package(url: "https://github.com/t-ae/xorswift", from: "3.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "GameEngine",
            dependencies: [
                .byName(name: "SystemFonts", condition: .when(platforms: [.macOS])),
                "AniTween",
                .product(name: "SDL2Swift", package: "SDL"),
                .product(name: "SDL2_TTFSwift", package: "SDL"),
                .product(name: "EonilFSEvents", package: "FSEvents", condition: .when(platforms: [.macOS])),
                .product(name: "ICU", package: "icu-swift"),
            ],
            cSettings: [.headerSearchPath("include"),],
	        swiftSettings: optimize//,
            //linkerSettings: [.unsafeFlags (["-Xlinker", "-undefined", "-Xlinker", "dynamic_lookup"])]
        ),
        .target(
            name: "SystemFonts",
            cSettings: [
                .headerSearchPath("include")
            ]
        ),
        .target(
            name: "AniTween",
            dependencies: [
                "ChunkedPool"
            ],
            swiftSettings: optimize
        ),
        .target(
            name: "ChunkedPool",
            swiftSettings: optimize
        ),
        .executableTarget(
            name: "ParticleTest",
            dependencies: [
                "GameEngine",
                .product(name: "Xorswift", package: "xorswift"),
            ],
            swiftSettings: optimize
        ),
        .executableTarget(
            name: "SpaceInvaders",
            dependencies: [
                "GameEngine"
            ],
            resources: [
                .copy("ExternalFiles/bullet.bmp"),
                .copy("ExternalFiles/oryx_16bit_scifi_vehicles_105.bmp"),
                .copy("ExternalFiles/oryx_16bit_scifi_vehicles_189.bmp"),
                .copy("ExternalFiles/Roboto-Medium.ttf")
            ],
            swiftSettings: optimize
        ),
        .testTarget(
            name: "GameEngineTests",
            dependencies: ["GameEngine"]),
    ]
)
