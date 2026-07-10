import Cocoa
import WebKit
import ServiceManagement

// Window that CAN become key — the override Plash/AetherDesk refuse, so typing works.
final class WallpaperWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// Interactive rectangle in PAGE coordinates (top-left origin), pushed from JS.
struct HitRect { let x: CGFloat; let y: CGFloat; let w: CGFloat; let h: CGFloat }

// First click both focuses the window and lands on the page element.
final class ClickThroughWebView: WKWebView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

// Serve bundled index.html from a STABLE origin (wallpaper://home) so localStorage
// persists on disk across relaunch. file:// origins are opaque and don't persist reliably.
final class LocalSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url,
              let file = Bundle.main.url(forResource: "index", withExtension: "html"),
              let data = try? Data(contentsOf: file) else {
            task.didFailWithError(URLError(.fileDoesNotExist)); return
        }
        let resp = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "text/html; charset=utf-8"])!
        task.didReceive(resp); task.didReceive(data); task.didFinish()
    }
    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}

final class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandler, NSMenuDelegate, WKNavigationDelegate {
    var window: WallpaperWindow!
    var statusItem: NSStatusItem!
    var web: ClickThroughWebView!
    var clickMonitor: Any?
    var passthroughTimer: Timer?
    // Interactive rects (todo panels) in page coords, pushed from JS. The move-handler
    // does a synchronous point-in-rect test against these — no async race.
    var hitRects: [HitRect] = []

    func applicationDidFinishLaunching(_ n: Notification) {
        let cfg = WKWebViewConfiguration()
        cfg.websiteDataStore = .default()
        cfg.setURLSchemeHandler(LocalSchemeHandler(), forURLScheme: "wallpaper")
        // Page posts todo-panel rects here on each render/resize.
        cfg.userContentController.add(self, name: "rects")

        web = ClickThroughWebView(frame: .zero, configuration: cfg)
        // Transparent web layer so the desktop (Finder icons) shows through the
        // page's empty areas. WKWebView paints an opaque backdrop by default;
        // drawsBackground=false (KVC — no public property) turns that off, and a
        // clear underPageBackgroundColor stops the overscroll/void fill.
        web.setValue(false, forKey: "drawsBackground")
        web.underPageBackgroundColor = .clear
        if #available(macOS 13.3, *) { web.isInspectable = true }
        web.autoresizingMask = [.width, .height]
        web.navigationDelegate = self   // re-show once the page paints (see showWindow rationale)
        web.load(URLRequest(url: URL(string: "wallpaper://home/index.html")!))

        let screen = NSScreen.main!
        window = WallpaperWindow(contentRect: screen.frame,
                                 styleMask: [.borderless],
                                 backing: .buffered, defer: false)
        // Primary level: desktop-icon band DOES receive key events. Covers desktop icons,
        // sits below every real app window. Fallback if it won't focus:
        //   NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.normalWindow)) - 1)
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)))
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        // Transparent window: no opaque black layer painting over Finder icons.
        // Desktop shows through wherever the page is empty.
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.setFrame(screen.frame, display: true)
        window.contentView = web
        // Show now, and again after a runloop tick + after the page paints. See showWindow.
        showWindow()
        DispatchQueue.main.async { [weak self] in self?.showWindow() }

        // The fix: after you click desktop icons, Finder becomes the active app and
        // steals keystrokes — our accessory window sits at desktop-icon level and won't
        // auto-reactivate our app on click. A GLOBAL mouse monitor sees clicks even while
        // we're inactive; when one lands inside our window we re-activate and reclaim the
        // first responder so typing works again. (Global MOUSE monitors need no a11y
        // permission; only keyboard monitors do.)
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            guard let self = self, let window = self.window else { return }
            // Only reclaim focus when we're actually capturing this click (cursor over a
            // panel). If ignoresMouseEvents is true the click is heading to Finder for a
            // folder — reactivating here would steal it back and break folder clicks.
            guard !window.ignoresMouseEvents,
                  window.frame.contains(NSEvent.mouseLocation) else { return }
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            window.makeFirstResponder(self.web)
        }

        // Region-aware click pass-through. The webview covers the whole screen and
        // AppKit hands it every click — even over transparent pixels — so clicks never
        // reach Finder's desktop icons. We toggle window.ignoresMouseEvents from the
        // cursor position: over a todo panel -> capture (typing works); over empty
        // desktop -> ignore (Finder gets the click, folders work, no Stage Manager reveal).
        //
        // We POLL the cursor on a timer instead of using mouseMoved monitors. Global
        // monitors miss/coalesce events while the app is inactive, so the flag was stale
        // at click time — the first click hit the desktop (Stage Manager) and only the
        // second landed. A ~60Hz synchronous poll of NSEvent.mouseLocation keeps the flag
        // correct before any click, no matter which app is active. Cheap: a point-in-rect
        // loop over 4 rects.
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updatePassthrough()
        }
        RunLoop.main.add(t, forMode: .common)   // .common so it fires during menu tracking too
        passthroughTimer = t

        buildMenu()
    }

    // Draw the wallpaper window. Called on launch, one runloop tick later, after the page
    // paints, and on reopen. WHY the redundancy: a single-click Finder launch of an
    // .accessory app doesn't fully activate the process, so a lone makeKeyAndOrderFront in
    // didFinishLaunching can no-op and the window never draws (only a double-click, which
    // sends an extra reopen event, forced it visible). Showing at several points guarantees
    // one of them lands after the process is live. orderFrontRegardless works even while
    // inactive; makeFirstResponder(web) reclaims typing.
    func showWindow() {
        guard let window = window else { return }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        window.makeFirstResponder(web)
    }

    // Page finished painting — show again so the first single-click launch reliably draws.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        showWindow()
    }

    // Clicking the Dock/Finder icon while we're already running sends this. Redraw so the
    // window reappears even if a cold single-click launch didn't fully activate us.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow()
        return true
    }

    // ---- Menu bar (all settings live here, not in the wallpaper UI) ----
    func buildMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "◔"
        let menu = NSMenu()
        menu.delegate = self   // menuNeedsUpdate refreshes checkmarks from the live page

        // Theme submenu
        let themeItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        let themeMenu = NSMenu()
        for (title, val) in [("Original", "original"), ("Neutral (white/grey)", "neutral"), ("White (pure white)", "white")] {
            let mi = NSMenuItem(title: title, action: #selector(setTheme(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = val
            themeMenu.addItem(mi)
        }
        themeItem.submenu = themeMenu
        menu.addItem(themeItem)

        // Background opacity submenu
        let bgItem = NSMenuItem(title: "Background", action: nil, keyEquivalent: "")
        let bgMenu = NSMenu()
        for pct in [0, 25, 50, 75, 100] {
            let label = pct == 0 ? "Transparent (0%)" : (pct == 100 ? "Solid (100%)" : "\(pct)%")
            let mi = NSMenuItem(title: label, action: #selector(setOpacity(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = pct
            bgMenu.addItem(mi)
        }
        bgItem.submenu = bgMenu
        menu.addItem(bgItem)

        menu.addItem(NSMenuItem.separator())

        let loginItem = NSMenuItem(title: "Open at Login",
            action: #selector(toggleLogin(_:)), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
        menu.addItem(loginItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Year Wallpaper",
            action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc func setTheme(_ sender: NSMenuItem) {
        guard let val = sender.representedObject as? String else { return }
        web.evaluateJavaScript("window.__wp && window.__wp.setTheme('\(val)')", completionHandler: nil)
    }

    @objc func setOpacity(_ sender: NSMenuItem) {
        guard let pct = sender.representedObject as? Int else { return }
        web.evaluateJavaScript("window.__wp && window.__wp.setOpacity(\(pct))", completionHandler: nil)
    }

    // Refresh checkmarks from the live page each time the menu opens. Async read is fine
    // here — the menu is already on screen; the marks update a frame later.
    func menuNeedsUpdate(_ menu: NSMenu) {
        web.evaluateJavaScript("JSON.stringify(window.__wp ? window.__wp.getSettings() : {})") { result, _ in
            guard let json = result as? String,
                  let data = json.data(using: .utf8),
                  let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            else { return }
            let theme = (obj["theme"] as? String) ?? "original"
            let opacity = (obj["opacity"] as? NSNumber)?.intValue ?? 0
            for item in menu.items {
                if item.title == "Theme", let sub = item.submenu {
                    for mi in sub.items {
                        mi.state = (mi.representedObject as? String == theme) ? .on : .off
                    }
                } else if item.title == "Background", let sub = item.submenu {
                    for mi in sub.items {
                        mi.state = (mi.representedObject as? Int == opacity) ? .on : .off
                    }
                }
            }
        }
    }

    // SYNCHRONOUS hit-test: is the cursor over a todo panel? Uses the cached rects the
    // page pushed — no async evaluateJavaScript, so the ignoresMouseEvents flag is always
    // correct the instant a click lands. Over a panel -> capture (typing works). Over
    // empty desktop -> ignore (Finder gets the click, folders + no stray desktop-reveal).
    func updatePassthrough() {
        guard let window = window else { return }
        let mouse = NSEvent.mouseLocation                 // screen coords, origin bottom-left
        let f = window.frame
        guard f.contains(mouse) else {
            window.ignoresMouseEvents = true
            return
        }
        let pageX = mouse.x - f.minX
        let pageY = f.maxY - mouse.y                        // flip to top-left origin (page coords)
        var over = false
        for r in hitRects {
            if pageX >= r.x && pageX <= r.x + r.w && pageY >= r.y && pageY <= r.y + r.h {
                over = true; break
            }
        }
        window.ignoresMouseEvents = !over
    }

    // Receive interactive rects from the page.
    func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "rects", let arr = message.body as? [[String: Any]] else { return }
        hitRects = arr.compactMap { d in
            // JS numbers bridge as NSNumber -> read as Double, then to CGFloat.
            guard let x = (d["x"] as? NSNumber)?.doubleValue,
                  let y = (d["y"] as? NSNumber)?.doubleValue,
                  let w = (d["w"] as? NSNumber)?.doubleValue,
                  let h = (d["h"] as? NSNumber)?.doubleValue
            else { return nil }
            return HitRect(x: CGFloat(x), y: CGFloat(y), w: CGFloat(w), h: CGFloat(h))
        }
        updatePassthrough()   // refresh immediately in case cursor already parked over a panel
    }

    // Toggle launch-at-login. SMAppService registers the app with the OS login-item
    // system (macOS 13+) — no helper bundle or privileged install needed.
    @objc func toggleLogin(_ sender: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                sender.state = .off
            } else {
                try SMAppService.mainApp.register()
                sender.state = .on
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Couldn't change login setting"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
