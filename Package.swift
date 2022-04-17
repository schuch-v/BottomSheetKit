// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "BottomSheetKit",
    platforms: [
        .iOS(.v11),
    ],
    products: [
        .library(
            name: "BottomSheetKit",
            targets: ["BottomSheetKit"]
        ),
    ],
    targets: [
        .target(name: "BottomSheetKit"),
    ]
)
