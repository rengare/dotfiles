// Closes Raycast's search window with Escape if it is on screen (Raycast
// ignores NSRunningApplication.hide()); exits 1 when it is not, so
// raycast-toggle.sh knows to open it instead. Compiled by that script.
import AppKit

let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
let shown = windows.contains { ($0[kCGWindowOwnerName as String] as? String) == "Raycast" }

guard shown,
      let raycast = NSRunningApplication.runningApplications(withBundleIdentifier: "com.raycast.macos").first
else { exit(1) }

// straight to Raycast's process: through the HID tap the key never reached it
let escape: CGKeyCode = 53
let source = CGEventSource(stateID: .hidSystemState)
for down in [true, false] {
    CGEvent(keyboardEventSource: source, virtualKey: escape, keyDown: down)?.postToPid(raycast.processIdentifier)
    usleep(20_000)
}
