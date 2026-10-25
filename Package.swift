// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Pomodoro",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Pomodoro", targets: ["Pomodoro"]),
        .executable(name: "make-icon", targets: ["make-icon"]),
        .executable(name: "snapshot", targets: ["snapshot"]),
    ],
    targets: [
        .target(name: "PomodoroCore"),
        .target(name: "PomodoroUI", dependencies: ["PomodoroCore"]),
        .executableTarget(name: "Pomodoro", dependencies: ["PomodoroUI"]),
        .executableTarget(name: "make-icon", dependencies: ["PomodoroCore"]),
        .executableTarget(name: "snapshot", dependencies: ["PomodoroCore", "PomodoroUI"]),
        .testTarget(name: "PomodoroCoreTests", dependencies: ["PomodoroCore"]),
    ]
)
