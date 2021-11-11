// swift-tools-version:5.3
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
        .library(
            name: "DataTracking",
            targets: ["DataTracking"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(
            name: "SageResearch",
            url: "https://github.com/Sage-Bionetworks/SageResearch.git",
            .branch("fix-internal-init")),
            //from: "4.1.0"),
        .package(
            name: "BridgeSDK",
            url: "https://github.com/Sage-Bionetworks/Bridge-iOS-SDK.git",
            from: "4.4.85"),
        .package(
            name: "JsonModel",
            url: "https://github.com/Sage-Bionetworks/JsonModel-Swift.git",
            from: "1.2.0"),
    ],
    targets: [

        .target(
            name: "BridgeApp",
            dependencies: [
                .product(name: "Research", package: "SageResearch"),
                .product(name: "ResearchUI", package: "SageResearch"),
                "BridgeSDK",
                "JsonModel",
            ],
            path: "BridgeApp/BridgeApp/iOS",
            resources: [
                .process("Localization"),
            ]),

        .target(
            name: "BridgeAppUI",
            dependencies: [
                .product(name: "Research", package: "SageResearch"),
                .product(name: "ResearchUI", package: "SageResearch"),
                "BridgeApp",
                "BridgeSDK",
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
                    "BridgeSDK",
                    "BridgeSDKSwizzle",
                ],
                path: "BridgeApp/BridgeApp_UnitTest"),
    
        .target(name: "BridgeSDKSwizzle",
                dependencies: ["BridgeSDK"],
                path: "BridgeApp/BridgeSDKSwizzle/"),
        
        .target(name: "DataTracking",
                dependencies: [
                    .product(name: "Research", package: "SageResearch"),
                    .product(name: "ResearchUI", package: "SageResearch"),
                    "BridgeApp",
                    "BridgeAppUI",
                ],
                path: "DataTracking/DataTracking/iOS",
                resources: [
                    .process("Resources"),
                ]
            ),
    ]
)
