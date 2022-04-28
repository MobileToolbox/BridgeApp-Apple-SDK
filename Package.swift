// swift-tools-version:5.3
// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BridgeApp",
    defaultLocalization: "en",
    platforms: [
        // Add support for all platforms starting from a specific version.
        .iOS(.v12),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "BridgeApp",
            targets: ["BridgeApp"]),
        .library(
            name: "BridgeAppUI",
            targets: ["BridgeAppUI"]),
        .library(
            name: "BridgeApp_UnitTest",
            targets: ["BridgeApp_UnitTest"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(
            name: "SageResearch",
            url: "https://github.com/Sage-Bionetworks/SageResearch.git",
            from: "4.4.0"),
        .package(
            name: "BridgeSDK",
            url: "https://github.com/Sage-Bionetworks/Bridge-iOS-SDK.git",
            from: "4.4.85"),
    ],
    targets: [

        .target(
            name: "BridgeApp",
            dependencies: [
                .product(name: "BridgeSDK", package: "BridgeSDK"),
                .product(name: "Research", package: "SageResearch"),
                .product(name: "ResearchUI", package: "SageResearch"),
            ],
            path: "BridgeApp/BridgeApp/iOS",
            resources: [
                .process("Localization"),
            ]),

        .target(
            name: "BridgeAppUI",
            dependencies: [
                "BridgeApp",
                .product(name: "Research", package: "SageResearch"),
                .product(name: "ResearchUI", package: "SageResearch"),
                .product(name: "BridgeSDK", package: "BridgeSDK"),
            ],
            path: "BridgeApp/BridgeAppUI/iOS",
            resources: [
                .process("Resources"),
            ]),
        
        .testTarget(name: "BridgeAppTests",
                    dependencies: [
                        "BridgeApp",
                        "BridgeApp_UnitTest",
                        .product(name: "Research_UnitTest", package: "SageResearch"),
                    ],
                    path:"BridgeApp/BridgeAppTests",
                    resources: [
                        .process("Resources"),
                    ]),
        
        .target(name: "BridgeApp_UnitTest",
                dependencies: [
                    "BridgeApp",
                    .product(name: "BridgeSDK", package: "BridgeSDK"),
                    "BridgeSDKSwizzle",
                ],
                path: "BridgeApp/BridgeApp_UnitTest"),
    
        .target(name: "BridgeSDKSwizzle",
                dependencies: [
                    .product(name: "BridgeSDK", package: "BridgeSDK"),
                ],
                path: "BridgeApp/BridgeSDKSwizzle/",
                linkerSettings: [
                    .linkedFramework("BridgeSDK")
                ]
               ),
    ]
)
