## macOS 26 (Tahoe): CBCentralManager crashes on init and scan

### Environment
- macOS 26 Tahoe (26.3.1, Darwin 25.3.0)
- universal_ble 0.x (latest)
- Flutter 3.x

### Summary

On macOS 26, four issues in CoreBluetooth/TCC enforcement cause crashes in `UniversalBlePlugin.swift`:

1. **Calling `scanForPeripherals` while state is `.unknown` causes SIGTERM.** On macOS 26, `centralManagerDidUpdateState` fires asynchronously after `CBCentralManager.init`. If `scanForPeripherals` is called before the delegate callback fires (i.e. while `manager.state` is still `.unknown`), the system terminates the process.

2. **`requestPermissions` times out waiting for `centralManagerDidUpdateState`.** The current implementation stores the Pigeon completion handler and waits for `centralManagerDidUpdateState` before calling it. On macOS 26, this callback can take long enough to exceed Flutter's ~2-second platform message reply timeout, causing the engine to kill the process.

3. **TCC kills the app if `CBCentralManager.init` is called while the app is not the active foreground application.** macOS 26 TCC enforcement crashes the process with `__TCC_CRASHING_DUE_TO_PRIVACY_VIOLATION__` (via `abort_with_payload`) if CBCentralManager is initialized without an active GUI audit session. This affects apps launched via `open` command, URL schemes, automation, or any context where the app is not yet frontmost when BLE is first used.

4. **`getBluetoothAvailabilityState` and `startScan` touch the lazy `manager` even when auth is `.denied`/`.restricted`.** On macOS 26, initializing `CBCentralManager` when authorization is already denied or restricted can trigger the TCC crash. These methods should check `CBCentralManager.authorization` first and return an appropriate error without touching the lazy `manager`.

### Root cause

macOS 26 Tahoe tightened CoreBluetooth and TCC (Transparency, Consent, and Control) enforcement. The system now terminates apps more aggressively when CBCentralManager is used in ways that were previously tolerated — specifically background queue initialization, premature scanning, and slow authorization flows.

### Suggested fixes (all in `UniversalBlePlugin.swift`)

**1. Defer `scanForPeripherals` until state is `.poweredOn`**

Add pending scan storage:
```swift
private var pendingScanServices: [CBUUID]? = nil
private var pendingScanOptions: [String: Any]? = nil
```

In `startScan`, check state before scanning:
```swift
if manager.state == .poweredOn {
    manager.scanForPeripherals(withServices: withServices, options: options)
} else {
    pendingScanServices = withServices
    pendingScanOptions = options
}
```

In `centralManagerDidUpdateState`, start deferred scan:
```swift
if central.state == .poweredOn, isManageScanning,
   let services = pendingScanServices, let options = pendingScanOptions {
    manager.scanForPeripherals(withServices: services, options: options)
    pendingScanServices = nil
    pendingScanOptions = nil
}
```

Also clear pending scan in `stopScan`:
```swift
func stopScan() throws {
    pendingScanServices = nil
    pendingScanOptions = nil
    manager.stopScan()
    isManageScanning = false
}
```

**2. Complete `requestPermissions` immediately after triggering lazy init**

```swift
// Before: store completion in requestPermissionStateUpdateHandlers and wait
// for centralManagerDidUpdateState to call it.

// After: trigger lazy init, then complete immediately.
// The deferred scan mechanism (fix #2) ensures scanForPeripherals
// won't be called until the manager is ready.
_ = manager
completion(.success(()))
```

**3. Guard `CBCentralManager.init` behind foreground activation on macOS**

On macOS 26, TCC crashes the app if `CBCentralManager.init` is called while the app is not the active foreground application. `NSApp.activate` is asynchronous, so we must wait for `didBecomeActiveNotification` before touching the manager:

```swift
#if os(OSX)
if !NSApp.isActive {
    NSApp.activate(ignoringOtherApps: true)
    var obs: NSObjectProtocol?
    var done = false
    let proceed = { [weak self] in
        guard !done, let self = self else { return }
        done = true
        if let o = obs { NotificationCenter.default.removeObserver(o); obs = nil }
        _ = self.manager
        completion(.success(()))
    }
    obs = NotificationCenter.default.addObserver(
        forName: NSApplication.didBecomeActiveNotification,
        object: nil, queue: .main) { _ in proceed() }
    // Fallback: if activation notification never fires, proceed after 500ms
    // (still well within Flutter's ~2s platform-message reply timeout).
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { proceed() }
    return
}
#endif
```

This should be placed in `requestPermissions` just before the `_ = manager` lazy init, in the `else` branch where `manager.state == .unknown`. It only fires on macOS and only when the app is not already active.

**4. Early-return for `.denied`/`.restricted` auth without touching the lazy `manager`**

In `getBluetoothAvailabilityState`:
```swift
let auth = CBCentralManager.authorization
if auth == .denied || auth == .restricted {
    completion(.success(AvailabilityState.unauthorized.rawValue))
    return
}
```

In `startScan`:
```swift
let auth = CBCentralManager.authorization
if auth == .denied || auth == .restricted {
    throw createFlutterError(code: .bluetoothUnauthorized,
        message: "Bluetooth access denied.")
}
```

This prevents needlessly initializing the `CBCentralManager` when the system has already denied access, avoiding the TCC crash path entirely.

All four fixes are in a single file and are backward-compatible with earlier macOS versions.
