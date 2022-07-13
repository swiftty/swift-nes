import SwiftUI
import SwiftNES

@main
struct MyApp: App {
    @StateObject var runner = CPURunner()

    var body: some Scene {
        WindowGroup {
            VStack {
                Canvas { context, size in
                    let xUnit = Int(size.width / 10)
                    let yUnit = Int(size.height / 10)
                    for y in 0..<yUnit {
                        for x in 0..<xUnit {
                            let (r, g, b) = runner.canvas[x + y * yUnit]
                            context.fill(Path(.init(x: x * 10, y: y * 10, width: 10, height: 10)),
                                         with: .color(red: Double(r), green: Double(g), blue: Double(b)))
                        }
                    }
                }
                .frame(width: 320, height: 320)

                Spacer(minLength: 40)

                VStack(spacing: 24) {
                    Button(action: runner.keyUp) {
                        Image(systemName: "arrow.up.square")
                    }
                    .keyboardShortcut(.upArrow, modifiers: [])

                    HStack(spacing: 96) {
                        Button(action: runner.keyLeft) {
                            Image(systemName: "arrow.left.square")
                        }
                        .keyboardShortcut(.leftArrow, modifiers: [])

                        Button(action: runner.keyRight) {
                            Image(systemName: "arrow.right.square")
                        }
                        .keyboardShortcut(.rightArrow, modifiers: [])
                    }

                    Button(action: runner.keyDown) {
                        Image(systemName: "arrow.down.square")
                    }
                    .keyboardShortcut(.downArrow, modifiers: [])
                }
                .font(.system(size: 60))

                Spacer()
            }
            .onAppear {
                runner.run()
            }
        }
    }
}

typealias RGB = (r: UInt8, g: UInt8, b: UInt8)

class CPURunner: ObservableObject {
    @Published var canvas: [RGB] = [RGB].init(repeating: (0, 0, 0), count: 32 * 32)

    private enum Direction {
        case up, down, left, right
    }
    private var cpu = CPU()
    private var direction: Direction?
    private let sync = DispatchQueue(label: "keycontrol")

    init() {
        cpu.load(program: program)
        cpu.reset()
    }

    func keyUp() {
        sync.async {
            self.direction = .up
        }
    }

    func keyDown() {
        sync.async {
            self.direction = .down
        }
    }

    func keyLeft() {
        sync.async {
            self.direction = .left
        }
    }

    func keyRight() {
        sync.async {
            self.direction = .right
        }
    }

    func run() {
        var frame = canvas
        var key = direction
        DispatchQueue.global().async {
            self.cpu.run { cpu in
                var direction: Direction?
                self.sync.sync {
                    direction = self.direction
                }
                if direction != key {
                    key = direction
                    switch key {
                    case .up:
                        cpu.mem_write(0x77, at: 0xff)

                    case .down:
                        cpu.mem_write(0x73, at: 0xff)

                    case .left:
                        cpu.mem_write(0x61, at: 0xff)

                    case .right:
                        cpu.mem_write(0x64, at: 0xff)

                    default:
                        break
                    }
                }

                cpu.mem_write((1..<16).randomElement()!, at: 0xfe)

                if readCanvas(from: cpu, frame: &frame) {
                    DispatchQueue.main.sync {
                        self.canvas = frame
                    }
                }

                Thread.sleep(forTimeInterval: 0.000007)
            }
            exit(1)
        }
    }
}

func color(_ byte: UInt8) -> RGB {
    switch byte {
    case 0: return (0, 0, 0)
    case 1: return (255, 255, 255)
    case 2, 9: return (127, 127, 127)
    case 3, 10: return (255, 0, 0)
    case 4, 11: return (0, 255, 0)
    case 5, 12: return (0, 0, 255)
    case 6, 13: return (255, 0, 255)
    case 7, 14: return (0, 255, 255)
    default: return (0, 156, 209)
    }
}

func readCanvas(from cpu: CPU, frame: inout [RGB]) -> Bool {
    var framei = 0
    var update = false
    for i in 0x0200..<0x0600 {
        let colori = cpu.mem_read(UInt16(i))
        let rgb = color(colori)

        if update || frame[framei] != rgb {
            frame[framei] = rgb
            update = true
        }
        framei += 1
    }
    return update
}

private let program: [UInt8] = [
    0x20, 0x06, 0x06, 0x20, 0x38, 0x06, 0x20, 0x0d, 0x06, 0x20, 0x2a, 0x06, 0x60, 0xa9, 0x02,
    0x85, 0x02, 0xa9, 0x04, 0x85, 0x03, 0xa9, 0x11, 0x85, 0x10, 0xa9, 0x10, 0x85, 0x12, 0xa9,
    0x0f, 0x85, 0x14, 0xa9, 0x04, 0x85, 0x11, 0x85, 0x13, 0x85, 0x15, 0x60, 0xa5, 0xfe, 0x85,
    0x00, 0xa5, 0xfe, 0x29, 0x03, 0x18, 0x69, 0x02, 0x85, 0x01, 0x60, 0x20, 0x4d, 0x06, 0x20,
    0x8d, 0x06, 0x20, 0xc3, 0x06, 0x20, 0x19, 0x07, 0x20, 0x20, 0x07, 0x20, 0x2d, 0x07, 0x4c,
    0x38, 0x06, 0xa5, 0xff, 0xc9, 0x77, 0xf0, 0x0d, 0xc9, 0x64, 0xf0, 0x14, 0xc9, 0x73, 0xf0,
    0x1b, 0xc9, 0x61, 0xf0, 0x22, 0x60, 0xa9, 0x04, 0x24, 0x02, 0xd0, 0x26, 0xa9, 0x01, 0x85,
    0x02, 0x60, 0xa9, 0x08, 0x24, 0x02, 0xd0, 0x1b, 0xa9, 0x02, 0x85, 0x02, 0x60, 0xa9, 0x01,
    0x24, 0x02, 0xd0, 0x10, 0xa9, 0x04, 0x85, 0x02, 0x60, 0xa9, 0x02, 0x24, 0x02, 0xd0, 0x05,
    0xa9, 0x08, 0x85, 0x02, 0x60, 0x60, 0x20, 0x94, 0x06, 0x20, 0xa8, 0x06, 0x60, 0xa5, 0x00,
    0xc5, 0x10, 0xd0, 0x0d, 0xa5, 0x01, 0xc5, 0x11, 0xd0, 0x07, 0xe6, 0x03, 0xe6, 0x03, 0x20,
    0x2a, 0x06, 0x60, 0xa2, 0x02, 0xb5, 0x10, 0xc5, 0x10, 0xd0, 0x06, 0xb5, 0x11, 0xc5, 0x11,
    0xf0, 0x09, 0xe8, 0xe8, 0xe4, 0x03, 0xf0, 0x06, 0x4c, 0xaa, 0x06, 0x4c, 0x35, 0x07, 0x60,
    0xa6, 0x03, 0xca, 0x8a, 0xb5, 0x10, 0x95, 0x12, 0xca, 0x10, 0xf9, 0xa5, 0x02, 0x4a, 0xb0,
    0x09, 0x4a, 0xb0, 0x19, 0x4a, 0xb0, 0x1f, 0x4a, 0xb0, 0x2f, 0xa5, 0x10, 0x38, 0xe9, 0x20,
    0x85, 0x10, 0x90, 0x01, 0x60, 0xc6, 0x11, 0xa9, 0x01, 0xc5, 0x11, 0xf0, 0x28, 0x60, 0xe6,
    0x10, 0xa9, 0x1f, 0x24, 0x10, 0xf0, 0x1f, 0x60, 0xa5, 0x10, 0x18, 0x69, 0x20, 0x85, 0x10,
    0xb0, 0x01, 0x60, 0xe6, 0x11, 0xa9, 0x06, 0xc5, 0x11, 0xf0, 0x0c, 0x60, 0xc6, 0x10, 0xa5,
    0x10, 0x29, 0x1f, 0xc9, 0x1f, 0xf0, 0x01, 0x60, 0x4c, 0x35, 0x07, 0xa0, 0x00, 0xa5, 0xfe,
    0x91, 0x00, 0x60, 0xa6, 0x03, 0xa9, 0x00, 0x81, 0x10, 0xa2, 0x00, 0xa9, 0x01, 0x81, 0x10,
    0x60, 0xa6, 0xff, 0xea, 0xea, 0xca, 0xd0, 0xfb, 0x60,
]
