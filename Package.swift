// swift-tools-version:5.7.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let optCSettings = ["-Os"]
let optimizeC = [CSetting.unsafeFlags(optCSettings)]
let optimize:[SwiftSetting] = []//[SwiftSetting.unsafeFlags(["-cross-module-optimization", "-Ounchecked", "-g", "-debug-info-format=dwarf", "-remove-runtime-asserts", "-enforce-exclusivity=unchecked"])]

#if os(Linux)
let icuDependency: Package.Dependency = .package(url: "https://github.com/izackp/icu-swift.git", branch: "master")
#else
let icuDependency: Package.Dependency = .package(path: "/Users/isaacpaul/Projects/swift-projects/icu-swift")
#endif

let package = Package(
    name: "GameEngine",
    platforms: [
        .macOS(.v12),
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "GameEngineLib",
            type: .static,
            targets: ["GameEngine"]),
        .library(
            name: "TennisCore",
            type: .static,
            targets: ["TennisCore"]),
        .library(
            name: "TennisInput",
            type: .static,
            targets: ["TennisInput"]),
        .executable(name: "ParticleTweenTest", targets: ["ParticleTest"]),
        .executable(name: "SpaceInvaders", targets: ["SpaceInvaders"]),
        .executable(name: "Tennis", targets: ["Tennis"]),
        .executable(name: "UITest", targets: ["UITest"]),
        .executable(name: "HeadlessRenderer", targets: ["HeadlessRenderer"])
    ],
    dependencies: [
        //.package(path: "/Users/isaacpaul/Projects/swift-projects/SDL"),
        icuDependency,
        .package(url: "https://github.com/izackp/SDL2-Swift.git", branch: "master"),
        .package(url: "https://github.com/izackp/EonilFSEvents.git", from:"0.1.7"),
        .package(url: "https://github.com/t-ae/xorswift", from: "3.0.0"),
        .package(url: "https://github.com/facebook/zstd", from: "1.5.7")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "GameEngine",
            dependencies: [
                .byName(name: "SystemFonts", condition: .when(platforms: [.macOS])),
                "AniTween",
                .byName(name: "ICUAliases", condition: .when(platforms: [.linux])),
                .product(name: "SDL2Swift", package: "SDL2-Swift"),
                .product(name: "SDL2_TTFSwift", package: "SDL2-Swift"),
                .product(name: "EonilFSEvents", package: "EonilFSEvents", condition: .when(platforms: [.macOS])),
                .product(name: "ICU", package: "icu-swift"),
                .product(name: "libzstd", package: "zstd")
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
        .target(
            name: "ICUAliases",
            path: "Sources/ICUAliases",
            publicHeadersPath: ".",
            linkerSettings: [
                .linkedLibrary("icui18n", .when(platforms: [.linux])),
                .linkedLibrary("icuuc", .when(platforms: [.linux])),
            ]
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
                .copy("ExternalFiles")
            ],
            swiftSettings: optimize
        ),
        .executableTarget(
            name: "Tennis",
            dependencies: [
                "GameEngine",
                "TennisCore",
                "TennisInput"
            ],
            swiftSettings: optimize
        ),
        .executableTarget(
            name: "UITest",
            dependencies: [
                "GameEngine"
            ],
            resources: [
                .copy("ExternalFiles")
            ],
            swiftSettings: optimize
        ),
        .executableTarget(
            name: "HeadlessRenderer",
            dependencies: [
                "GameEngine",
                .product(name: "SDL2Swift", package: "SDL2-Swift"),
                .product(name: "SDL2_TTFSwift", package: "SDL2-Swift"),
            ],
            swiftSettings: optimize
        ),
        .testTarget(
            name: "GameEngineTests",
            dependencies: ["GameEngine", "SpaceInvaders"]),
        .testTarget(
            name: "TennisCoreTests",
            dependencies: ["TennisCore"]),
        .target(
            name: "TennisCore",
            dependencies: [],
            swiftSettings: optimize),
        .target(
            name: "TennisInput",
            dependencies: ["GameEngine", "TennisCore"],
            swiftSettings: optimize),
        .testTarget(
            name: "TennisInputTests",
            dependencies: ["TennisInput", "TennisCore", "GameEngine"]),
        .testTarget(
            name: "TennisTests",
            dependencies: ["Tennis", "TennisCore", "TennisInput", "GameEngine"]),
    ]
)
