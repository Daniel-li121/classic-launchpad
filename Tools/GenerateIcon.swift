import AppKit

let output = CommandLine.arguments.dropFirst().first ?? "AppIcon.png"
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()
guard let context = NSGraphicsContext.current?.cgContext else {
    fatalError("Unable to create graphics context")
}

let outer = CGRect(x: 52, y: 52, width: 920, height: 920)
let path = CGPath(roundedRect: outer, cornerWidth: 214, cornerHeight: 214, transform: nil)
context.saveGState()
context.addPath(path)
context.clip()

let colors = [
    NSColor(calibratedRed: 0.24, green: 0.58, blue: 0.98, alpha: 1).cgColor,
    NSColor(calibratedRed: 0.46, green: 0.22, blue: 0.86, alpha: 1).cgColor
] as CFArray
let space = CGColorSpaceCreateDeviceRGB()
let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1])!
context.drawLinearGradient(gradient, start: CGPoint(x: 150, y: 930), end: CGPoint(x: 880, y: 90), options: [])

context.setFillColor(NSColor.white.withAlphaComponent(0.16).cgColor)
context.fillEllipse(in: CGRect(x: -100, y: 560, width: 850, height: 650))
context.restoreGState()

let tileSize: CGFloat = 178
let gap: CGFloat = 54
let origin = (1024 - (tileSize * 3 + gap * 2)) / 2
for row in 0..<3 {
    for column in 0..<3 {
        let x = origin + CGFloat(column) * (tileSize + gap)
        let y = origin + CGFloat(row) * (tileSize + gap)
        let tile = CGRect(x: x, y: y, width: tileSize, height: tileSize)
        context.setShadow(offset: CGSize(width: 0, height: -8), blur: 18, color: NSColor.black.withAlphaComponent(0.22).cgColor)
        context.setFillColor(NSColor.white.withAlphaComponent(0.94).cgColor)
        context.addPath(CGPath(roundedRect: tile, cornerWidth: 42, cornerHeight: 42, transform: nil))
        context.fillPath()
    }
}

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Unable to encode icon")
}
try png.write(to: URL(fileURLWithPath: output))
