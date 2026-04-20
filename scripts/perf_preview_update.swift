import AppKit
import Foundation

@inline(__always)
func measure(label: String, iterations: Int, block: () -> Void) {
    let start = CFAbsoluteTimeGetCurrent()
    for _ in 0..<iterations {
        block()
    }
    let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000.0
    let avg = elapsed / Double(iterations)
    print("\(label): total \(String(format: "%.2f", elapsed)) ms, avg \(String(format: "%.3f", avg)) ms")
}

let repeatCount = 6000
let largeText = String(repeating: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ\n", count: repeatCount)

let textView = NSTextView()
textView.isEditable = false
textView.isSelectable = true
textView.isRichText = false
textView.allowsUndo = false
textView.string = largeText

let sameTextIterations = 400
let changeTextIterations = 50

print("Benchmark payload size: \(largeText.count) chars")

measure(label: "Baseline (always reset selection+scroll, same text)", iterations: sameTextIterations) {
    textView.setSelectedRange(NSRange(location: 0, length: 0))
    textView.scrollToBeginningOfDocument(nil)
}

measure(label: "Optimized (same text, no-op)", iterations: sameTextIterations) {
    // Simulate guarded updateNSView: text did not change, so no work.
}

measure(label: "Text changed (assign + reset + scroll)", iterations: changeTextIterations) {
    let updated = largeText + UUID().uuidString
    textView.string = updated
    textView.setSelectedRange(NSRange(location: 0, length: 0))
    textView.scrollToBeginningOfDocument(nil)
}
