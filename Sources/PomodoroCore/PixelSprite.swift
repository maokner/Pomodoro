import Foundation

/// A one-bit pixel-art bitmap. `#` is a lit pixel, anything else is empty.
public struct PixelSprite: Equatable, Sendable {
    public let width: Int
    public let height: Int
    private let pixels: [Bool]

    public init(_ rows: [String]) {
        let width = rows.map(\.count).max() ?? 0
        self.width = width
        height = rows.count
        pixels = rows.flatMap { row in
            row.map { $0 == "#" } + Array(repeating: false, count: width - row.count)
        }
    }

    public func isLit(x: Int, y: Int) -> Bool {
        guard (0..<width).contains(x), (0..<height).contains(y) else { return false }
        return pixels[y * width + x]
    }

    /// Lit pixel coordinates, for renderers that draw one rect per pixel.
    public var litPixels: [(x: Int, y: Int)] {
        (0..<height).flatMap { y in (0..<width).compactMap { x in isLit(x: x, y: y) ? (x, y) : nil } }
    }
}

public enum CatSprites {
    /// Curled up and asleep, head on the left. Shown during focus.
    public static let sleeping = PixelSprite([
        "..........#.......########",
        "..........##...#############",
        ".........###..################",
        ".........####.#################",
        "......########.#################",
        "##...##########.#################",
        "###############.#################",
        "################.######..#########",
        ".###############.#####.############",
        ".############.##.####.#############",
        "..#########..###.####.#############",
        "..#####.#######.#####.#############",
        "..###...#######.#####.#############",
        "...#######.###.#######.#######.####",
        "....#########.######..#######.####",
        "...#..######.#....#.######...#####",
        "..####......#.####........#######",
        "..######.####.##################",
        "..######.####.################",
        "...####...###..#############",
    ])

    /// Sitting up and awake. Shown during breaks.
    public static let awake = PixelSprite(awakeRows(eyes: .open, tail: .down))
    public static let awakeBlinking = PixelSprite(awakeRows(eyes: .closed, tail: .down))
    public static let awakeTailUp = PixelSprite(awakeRows(eyes: .open, tail: .up))

    private enum Eyes { case open, closed }
    private enum Tail { case down, up }

    private static func awakeRows(eyes: Eyes, tail: Tail) -> [String] {
        let eyeRows = switch eyes {
        case .open: ["...###.#####.###........", "...###.#####.###........"]
        case .closed: ["...#############........", "...###.#####.###........"]
        }
        let tailRows = switch tail {
        case .down: ["...#############........", "...######.######....##.."]
        case .up: ["...#############.....##.", "...######.######.....##."]
        }
        return [
            "....#.........#.........",
            "....##.......##.........",
            "....###.....###.........",
            "....###########.........",
            "...#############........",
            "...#############........",
        ] + eyeRows + [
            "...######.######........",
            "....###########.........",
            ".....#########..........",
            "....###########.........",
        ] + tailRows + [
            "..#######.#######....##.",
            "..#######.#######....##.",
            "..#######.#######...###.",
            "..################.###..",
            "..###.#####.#########...",
            "...##..###..#######.....",
        ]
    }
}

/// The "z" dots that float above the sleeping cat while a focus session runs.
/// Every half second one more dot appears (up to four), then the newer three fade and the cycle restarts.
/// The first dot never goes away.
public enum SleepDots {
    public struct Dot: Equatable, Sendable {
        /// Center, in sprite pixels relative to the top-left of `CatSprites.sleeping`. Can be negative.
        public let x: Double
        public let y: Double
        public let opacity: Double
    }

    /// Side length of a dot, in sprite pixels. The dots are a little chunkier than the cat's pixels.
    public static let size = 1.5
    public static let stepDuration: TimeInterval = 0.5
    public static let fadedOpacity = 0.55

    static let positions: [(x: Double, y: Double)] = [(6.5, -1.3), (2, -3.25), (5, -5.55), (-0.8, -7.05)]
    private static let steps = positions.count + 1

    /// The dots to draw `elapsed` seconds after the session started.
    public static func frame(elapsed: TimeInterval) -> [Dot] {
        let step = Int((max(elapsed, 0) / stepDuration).rounded(.down)) % steps
        if step < positions.count {
            return positions[...step].map { Dot(x: $0.x, y: $0.y, opacity: 1) }
        }
        return positions.enumerated().map { index, position in
            Dot(x: position.x, y: position.y, opacity: index == 0 ? 1 : fadedOpacity)
        }
    }

    /// How far the dots reach beyond the sprite's top and left edges, in sprite pixels.
    public static var overhang: (left: Double, top: Double) {
        (
            left: max(0, -(positions.map(\.x).min()! - size / 2)),
            top: max(0, -(positions.map(\.y).min()! - size / 2))
        )
    }
}
