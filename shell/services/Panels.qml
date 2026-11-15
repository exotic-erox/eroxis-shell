pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    property bool launcherOpen: false
    property string launcherQuery: ""
    property bool systemOpen: false
    property bool batteryOpen: false
    property bool wallpaperOpen: false
    property bool controlOpen: false
    property bool mediaOpen: false
    property bool nightOpen: false
    property bool soundOpen: false
    property bool overviewOpen: false
    property bool awakeOpen: false
    property bool appsOpen: false
    property bool wifiOpen: false
    property bool wifiTyping: false
    property bool vpnOpen: false
    property bool wikiOpen: false
    property string wikiQuery: ""
    property bool keyboardOpen: false
    property bool bluetoothOpen: false
    property bool captureOpen: false
    property bool powerOpen: false
    property bool privacyOpen: false
    property string timerTab: ""
    property bool timerOpen: false
    property bool settingsOpen: false
    property bool welcomeOpen: false
    property bool helpOpen: false
    property bool calendarOpen: false
    property bool hotspotOpen: false

    readonly property var islandPanels: [
        "launcher", "system", "battery", "wallpaper", "control", "media", "night", "sound", "overview",
        "awake", "apps", "wiki", "wifi", "vpn", "keyboard", "bluetooth", "capture", "power", "privacy", "timer", "hotspot",
    ]

    function only(name) {
        for (const p of islandPanels)
            if (p !== name && root[p + "Open"]) root[p + "Open"] = false;
    }
    function wiki(query) { wikiQuery = query ?? ""; wikiOpen = true; }
    function closeAll() { only(""); }

    onLauncherOpenChanged: if (launcherOpen) only("launcher")
    onSystemOpenChanged: if (systemOpen) only("system")
    onBatteryOpenChanged: if (batteryOpen) only("battery")
    onWallpaperOpenChanged: if (wallpaperOpen) only("wallpaper")
    onControlOpenChanged: if (controlOpen) only("control")
    onMediaOpenChanged: if (mediaOpen) only("media")
    onNightOpenChanged: if (nightOpen) only("night")
    onSoundOpenChanged: if (soundOpen) only("sound")
    onOverviewOpenChanged: if (overviewOpen) only("overview"); else overviewByAlt = false
    onAwakeOpenChanged: if (awakeOpen) only("awake")
    onAppsOpenChanged: if (appsOpen) only("apps")
    onWifiOpenChanged: if (wifiOpen) only("wifi")
    onVpnOpenChanged: if (vpnOpen) only("vpn")
    onWikiOpenChanged: if (wikiOpen) only("wiki")
    onKeyboardOpenChanged: if (keyboardOpen) only("keyboard")
    onBluetoothOpenChanged: if (bluetoothOpen) only("bluetooth")
    onCaptureOpenChanged: if (captureOpen) only("capture")
    onPowerOpenChanged: if (powerOpen) only("power")
    onTimerOpenChanged: if (timerOpen) only("timer")
    onPrivacyOpenChanged: if (privacyOpen) only("privacy")
    onHotspotOpenChanged: if (hotspotOpen) only("hotspot")

    property string app: ""
    readonly property var appFlags: ({ settings: "settings", help: "help", calendar: "calendar" })
    function openApp(name, call, arg) {
        if (app === name) { root[appFlags[name] + "Open"] = true; return; }
        Quickshell.execDetached([Quickshell.shellPath("scripts/app.sh"), name, call || "open", arg ?? ""]);
    }
    function closeApp(name) {
        if (app === name) { root[appFlags[name] + "Open"] = false; return; }
        Quickshell.execDetached([Quickshell.shellPath("scripts/app.sh"), name, "close"]);
    }
    function inShell(target, fn) {
        Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("shell.qml"), "ipc", "call", target, fn]);
    }
    onSettingsOpenChanged: handOver("settings")
    onHelpOpenChanged: handOver("help")
    function handOver(name) {
        const flag = appFlags[name] + "Open";
        if (app === name || !root[flag]) return;
        root[flag] = false;
        openApp(name);
    }

    property string settingsPage: "appearance"
    signal settingsSearchRequested(string text)
    function settingsSearch(text) {
        if (app !== "settings") { openApp("settings", "search", text); return; }
        settingsOpen = true;
        settingsSearchRequested(text);
    }
    readonly property var islandPages: ({ night: ["nightlight", "nightOpen"] })
    function islandPage(page) {
        const p = islandPages[page];
        if (!p) return false;
        if (app) inShell(p[0], "panel");
        else root[p[1]] = true;
        return true;
    }
    function settings(page) {
        if (islandPage(page)) return;
        if (page === "welcome") { if (app) inShell("welcome", "open"); else welcomeOpen = true; return; }
        if (page === "help") { openApp("help"); return; }
        if (app !== "settings") { openApp("settings", "page", page ?? ""); return; }
        settingsOpen = true;
        if (page) settingsPage = page;
    }
    property string settingsFocus: ""
    function settingsRow(page, title) {
        if (islandPage(page)) return;
        if (app !== "settings") { openApp("settings", "row", page + "\t" + (title ?? "")); return; }
        settings(page);
        settingsFocus = title ?? "";
    }

    function search(text) {
        launcherQuery = text;
        launcherOpen = true;
    }

    function keyboard() {
        if (keyboardOpen) Keyboard.next();
        else keyboardOpen = true;
    }

    signal overviewStep(int delta)
    function overview(delta) {
        if (overviewOpen) overviewStep(delta);
        else { overviewByAlt = true; overviewOpen = true; }
    }
    property bool overviewByAlt: false
    signal overviewCommitted()
    property bool overviewCommitPending: false
    function overviewCommit() {
        if (overviewOpen) { if (overviewByAlt) overviewCommitted(); }
        else { overviewCommitPending = true; commitExpiry.restart(); }
    }
    property Timer commitExpiry: Timer { interval: 500; onTriggered: root.overviewCommitPending = false }

    readonly property bool anyIslandPanel: islandPanels.some(p => root[p + "Open"])
    readonly property bool needsKeyboard: wifiTyping || launcherOpen || appsOpen || wikiOpen || powerOpen || wallpaperOpen || overviewOpen || keyboardOpen || captureOpen || timerOpen || nightOpen
}
