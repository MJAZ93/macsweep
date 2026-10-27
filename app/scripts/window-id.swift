// Prints "<CGWindowID> <x>,<y>,<w>,<h>" for an on-screen window of the given app:
// the frontmost one, or with --largest the biggest (the main window, not its sheet).
import CoreGraphics
import Foundation

let args = CommandLine.arguments.dropFirst()
let owner = args.first { !$0.hasPrefix("--") } ?? "MacSweep"
let largest = args.contains("--largest")
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
let mine = list.filter { ($0[kCGWindowOwnerName as String] as? String) == owner && ($0[kCGWindowLayer as String] as? Int) == 0 }
func bounds(_ w: [String: Any]) -> (Int, Int, Int, Int) {
    let b = w[kCGWindowBounds as String] as? [String: Any] ?? [:]
    func n(_ k: String) -> Int { Int((b[k] as? Double) ?? Double((b[k] as? Int) ?? 0)) }
    return (n("X"), n("Y"), n("Width"), n("Height"))
}
let pick = largest ? mine.max { bounds($0).2 * bounds($0).3 < bounds($1).2 * bounds($1).3 } : mine.first
guard let w = pick else { exit(1) }
let (x, y, wd, h) = bounds(w)
print("\(w[kCGWindowNumber as String] as? Int ?? 0) \(x),\(y),\(wd),\(h)")
