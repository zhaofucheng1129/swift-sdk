import PackageDescription

let package = Package(
    name: "LeanCloud",
    dependencies: [
        .Package(url: "https://github.com/leancloud/Akara.git", majorVersion: 0, minor: 0)
    ]
)
