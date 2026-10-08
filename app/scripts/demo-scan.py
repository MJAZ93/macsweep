#!/usr/bin/env python3
"""Writes a realistic scan.dat for screenshots: python3 demo-scan.py out.dat
Run the app with MACSWEEP_DEMO_DUMP=out.dat to show it instead of a real scan."""
import sys

U = "/Users/afonso"
G = 1048576
ITEMS = [
    ("SAFE", "Xcode iOS DeviceSupport (old versions)", "symbols for iOS versions your iPhone no longer runs; newest kept", "", "rm", 22.1,
     [U + "/Library/Developer/Xcode/iOS DeviceSupport/iPhone15,2 17.4 (21E219)", U + "/Library/Developer/Xcode/iOS DeviceSupport/iPhone15,2 17.5.1 (21F90)"]),
    ("SAFE", "Gradle caches", "dependencies and build cache; re-downloaded on next build", "", "rm", 9.8, [U + "/.gradle/caches", U + "/.gradle/daemon"]),
    ("SAFE", "Xcode DerivedData", "intermediate builds; next build is slower once", "Xcode", "rm", 7.4, [U + "/Library/Developer/Xcode/DerivedData"]),
    ("SAFE", "npm cache", "", "", "rm", 6.2, [U + "/.npm/_cacache"]),
    ("SAFE", "JetBrains caches + logs", "indexes and logs for every JetBrains IDE; rebuilt on next open", "", "rm", 4.9, [U + "/Library/Caches/JetBrains"]),
    ("SAFE", "Homebrew cache + old versions", "runs 'brew cleanup --prune=all'", "", "brew", 3.1, [U + "/Library/Caches/Homebrew"]),
    ("SAFE", "AVD Pixel_8_API_35: snapshots", "quick-boot state only; the emulator cold-boots once", "", "rm", 2.6, [U + "/.android/avd/Pixel_8_API_35.avd/snapshots"]),
    ("SAFE", "Go build cache", "", "", "rm", 1.9, [U + "/Library/Caches/go-build"]),
    ("REBUILD", "webshop: build artifacts (inactive for 74 days)", "node_modules, build, Pods, .venv… reinstall when you return", "", "rm", 4.4,
     [U + "/Projects/webshop/node_modules", U + "/Projects/webshop/ios/Pods"]),
    ("REBUILD", "Go module cache (~/go/pkg/mod)", "re-downloaded with 'go mod download'", "", "rm", 3.7, [U + "/go/pkg/mod"]),
    ("REVIEW", "Simulator runtime iOS 17.5", "all simulators on this runtime become unusable; re-download in Xcode > Settings > Components", "", "sim_runtime X", 17.2,
     ["/Library/Developer/CoreSimulator/Volumes/iOS_21F79"]),
    ("REVIEW", "AVD Pixel_8_API_35: wipe data", "factory reset: removes installed apps and data, keeps the device", "", "rm", 10.3,
     [U + "/.android/avd/Pixel_8_API_35.avd/userdata-qemu.img.qcow2"]),
    ("REVIEW", "Docker VM", "images, containers and build cache live inside this file", "!Docker Desktop is not running: start it and rerun to prune", "none", 8.9, []),
]
f = ["macsweep-ui-1", "1.1.0", "en", str(494 * G), str(int(0.6 * G)), U + "/Projects", "0", "50", U + "/Library/Logs/macsweep.log", str(len(ITEMS))]
for tier, label, note, block, handler, gb, paths in ITEMS:
    f += [tier, label, note, block, handler, str(int(gb * G)), "".join(p + "\n" for p in paths)]
open(sys.argv[1], "wb").write(("\0".join(f) + "\0").encode())
