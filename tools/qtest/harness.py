# SPDX-License-Identifier: GPL-3.0-or-later
#!/usr/bin/env python3
"""Test setup for the control center: loads ControlView.qml in a headless Qt runtime, with stand-ins for Quickshell, the services and the components,
and reports whether it loads, what size it comes to, and every warning the engine prints."""
import os, re, shutil, subprocess, sys, pathlib

import tempfile
SHELL = pathlib.Path(__file__).resolve().parents[2] / "shell"
H = pathlib.Path(tempfile.gettempdir()) / "eroxis-qtest"

ITEM_PROPS = set("""x y z width height visible opacity enabled clip focus scale rotation implicitWidth implicitHeight
parent children data resources state states transitions anchors baselineOffset antialiasing smooth transformOrigin
activeFocus containmentMask layer objectName id default readonly""".split())
QT_TYPES = set("""Item Rectangle Text Image ColumnLayout RowLayout GridLayout Row Column Grid Flow Repeater Loader Timer Connections
Component MouseArea Behavior NumberAnimation ColorAnimation PropertyAnimation SequentialAnimation ParallelAnimation PauseAnimation
Gradient GradientStop ListView Flickable QtObject Binding Shape ShapePath Canvas FocusScope Scale Rotation Translate
MultiEffect From To Font Qt Math JSON""".split())
QS_TYPES = {"ClippingRectangle": "Quickshell.Widgets", "PwObjectTracker": "Quickshell.Services.Pipewire"}

def statements(block):
    """Top-level statements of an object body: split on ; and newlines outside any brackets or strings."""
    out, cur, d, q = [], [], 0, None
    i = 0
    while i < len(block):
        c = block[i]
        if q:
            cur.append(c)
            if c == "\\": cur.append(block[i + 1]); i += 1
            elif c == q: q = None
        elif c in "\"'`": q = c; cur.append(c)
        elif c in "({[": d += 1; cur.append(c)
        elif c in ")}]": d -= 1; cur.append(c)
        elif c == "/" and block[i:i + 2] == "//":
            while i < len(block) and block[i] != "\n": i += 1
            continue
        elif c in ";\n" and d == 0:
            out.append("".join(cur)); cur = []
        else: cur.append(c)
        i += 1
    out.append("".join(cur))
    return [x.strip() for x in out if x.strip()]

def depth1_props(block):
    props, handlers = set(), set()
    for st in statements(block):
        m = re.match(r"([a-z]\w*)\s*:", st)
        if m: props.add(m.group(1))
        m = re.match(r"on([A-Z]\w*)\s*:", st)
        if m: handlers.add(m.group(1))
        m = re.match(r"function\s+on([A-Z]\w*)\s*\(", st)
        if m: handlers.add(m.group(1))
    return props, handlers

def match_close(s, i):
    d = 0
    for j in range(i, len(s)):
        d += (s[j] == "{") - (s[j] == "}")
        if d == 0: return j
    return len(s)

THEME_NUM = {"barHeight": 36, "panelInset": 12, "panelTop": 8, "fontSize": 14, "fontSizeSmall": 12, "fontSizeLabel": 12,
             "durationFast": 0, "durationNormal": 0, "durationSlow": 0}
def theme_default(name):
    if name in THEME_NUM: return str(THEME_NUM[name])
    if name.startswith("space") or name.endswith("Inset") or name.startswith("duration"): return "10"
    if name in ("slanted",): return "false"
    if name in ("fontFamily", "monoFamily"): return '"sans"'
    return '"#808080"'

def build(candidate, extra_files=(), companions=()):
    if H.exists(): shutil.rmtree(H)
    for d in ["shell/config", "shell/components", "shell/services", "shell/modules/island"]: (H / d).mkdir(parents=True)
    (H / "qs").symlink_to(H / "shell")
    shutil.copy(SHELL / "components/PanelBody.qml", H / "shell/components/")
    shutil.copy(SHELL / "components/Slant.js", H / "shell/components/")
    for f in (SHELL / "components").glob("*.js"): shutil.copy(f, H / "shell/components" / f.name)
    for f in extra_files:
        dst = H / "shell" / pathlib.Path(f).relative_to(SHELL); dst.parent.mkdir(parents=True, exist_ok=True); shutil.copy(f, dst)
    text = pathlib.Path(candidate).read_text()
    (H / "shell/modules/island/ControlView.qml").write_text(text)
    for c in companions:
        (H / "shell/modules/island" / pathlib.Path(c).name).write_text(pathlib.Path(c).read_text())
        text += "\n" + pathlib.Path(c).read_text()

    # ---- which names are what
    real_components = {f.stem: f for f in (SHELL / "components").glob("*.qml")}
    island_dir = {f.stem for f in (SHELL / "modules/island").glob("*.qml")}
    skip_types = {pathlib.Path(c).stem for c in companions}
    services = {f.stem for f in (SHELL / "services").glob("*.qml") if "pragma Singleton" in f.read_text()}
    config_singletons = {"Theme", "Config", "Tr"}
    types_used = set(re.findall(r"(?<![\w.])([A-Z]\w+)\s*\{", text))
    inline = set(re.findall(r"\bcomponent\s+(\w+)\s*:", text))
    singles_used = {}
    for m in re.finditer(r"(?<![\w.])([A-Z]\w+)\.(\w+)(\s*\()?", text):
        n, mem, call = m.group(1), m.group(2), bool(m.group(3))
        if n in services or n in config_singletons: singles_used.setdefault(n, {})[mem] = singles_used.get(n, {}).get(mem, False) or call
    # members used by the real PanelBody and Slant
    pb = (SHELL / "components/PanelBody.qml").read_text()
    for m in re.finditer(r"Theme\.(\w+)", pb): singles_used.setdefault("Theme", {}).setdefault(m.group(1), False)

    # ---- module stubs
    def module(path, files, qmldir_lines):
        d = H / path; d.mkdir(parents=True, exist_ok=True)
        for name, body in files.items(): (d / name).write_text(body)
        (d / "qmldir").write_text("module %s\n%s\n" % (path.replace("/", "."), "\n".join(qmldir_lines)))
    module("Quickshell", {"SystemClock.qml": "import QtQuick\nQtObject { enum Precision { Seconds, Minutes, Hours }\n property int precision: 1\n property date date: new Date() }\n", "Quickshell.qml": "pragma Singleton\nimport QtQuick\nQtObject { function execDetached() {} function env(k) { return \"\" } property var screens: [] }\n"},
           ["singleton Quickshell 1.0 Quickshell.qml", "SystemClock 1.0 SystemClock.qml"])
    module("Quickshell/Widgets", {"ClippingRectangle.qml": "import QtQuick\nRectangle { property var contentInsideBorder; property var contentItem }\n"}, ["ClippingRectangle 1.0 ClippingRectangle.qml"])
    module("Quickshell/Services/Pipewire", {
        "PwObjectTracker.qml": "import QtQuick\nQtObject { property var objects }\n",
        "Pipewire.qml": "pragma Singleton\nimport QtQuick\nQtObject { property var defaultAudioSink: null; property var defaultAudioSource: null }\n"},
        ["PwObjectTracker 1.0 PwObjectTracker.qml", "singleton Pipewire 1.0 Pipewire.qml"])
    module("Quickshell/Bluetooth", {"Bluetooth.qml": "pragma Singleton\nimport QtQuick\nQtObject { property var defaultAdapter: null; property var devices: ({ values: [] }) }\n"}, ["singleton Bluetooth 1.0 Bluetooth.qml"])
    module("Quickshell/Networking", {
        "Networking.qml": "pragma Singleton\nimport QtQuick\nQtObject { property var devices: ({ values: [] }); property bool wifiEnabled: true }\n",
        "DeviceType.qml": "pragma Singleton\nimport QtQuick\nQtObject { enum Kind { Wifi = 1 } }\n"},
        ["singleton Networking 1.0 Networking.qml", "singleton DeviceType 1.0 DeviceType.qml"])
    module("Quickshell/Services/UPower", {"PowerProfile.qml": "pragma Singleton\nimport QtQuick\nQtObject { enum Kind { PowerSaver, Balanced, Performance } }\n"}, ["singleton PowerProfile 1.0 PowerProfile.qml"])

    # ---- qs.config
    cfg_lines = []
    theme = singles_used.get("Theme", {})
    body = "".join("    property var %s: %s\n" % (k, theme_default(k)) if not v else "" for k, v in theme.items() if k not in ("r", "hairlineOn", "tint"))
    body += "    function r(n) { return n }\n    function hairlineOn(x) { return \"#333333\" }\n    function tint(a, b, c) { return \"#333333\" }\n"
    (H / "shell/config/Theme.qml").write_text("pragma Singleton\nimport QtQuick\nQtObject {\n%s}\n" % body); cfg_lines.append("singleton Theme 1.0 Theme.qml")
    (H / "shell/config/Tr.qml").write_text("pragma Singleton\nimport QtQuick\nQtObject { function t(s) { return s } function f(s, a) { return s } }\n"); cfg_lines.append("singleton Tr 1.0 Tr.qml")
    (H / "shell/config/Config.qml").write_text(CONFIG_STUB); cfg_lines.append("singleton Config 1.0 Config.qml")
    for f in (SHELL / "config").glob("*.js"): shutil.copy(f, H / "shell/config" / f.name)
    (H / "shell/config/qmldir").write_text("module qs.config\n" + "\n".join(cfg_lines) + "\n")

    # ---- qs.services: a stand-in per singleton, with the members used
    svc_lines = []
    for n in sorted(services):
        members = singles_used.get(n, {})
        body = ""
        for k, call in members.items():
            if call: body += "    function %s() { return null }\n" % k
            else: body += "    property var %s: %s\n" % (k, SVC_DEFAULTS.get((n, k), "null"))
        (H / "shell/services" / (n + ".qml")).write_text("pragma Singleton\nimport QtQuick\nQtObject {\n%s}\n" % body)
        svc_lines.append("singleton %s 1.0 %s.qml" % (n, n))
    (H / "shell/services/qmldir").write_text("module qs.services\n" + "\n".join(svc_lines) + "\n")

    # ---- components: stand-ins with the properties used
    comp_lines = ["PanelBody 1.0 PanelBody.qml"]
    for T in sorted(types_used):
        if T in QT_TYPES or T in inline or T in QS_TYPES or T == "PanelBody" or T in skip_types or T == "SystemClock": continue
        props, handlers = set(), set()
        for m in re.finditer(r"(?<![\w.])" + T + r"\s*\{", text):
            ob = text.index("{", m.start()); blk = text[ob + 1:match_close(text, ob)]
            p, h = depth1_props(blk); props |= p; handlers |= h
        # members reached through the id of an object of this type (id.member, aliases)
        for m in re.finditer(r"(?<![\w.])" + T + r"\s*\{", text):
            ob = text.index("{", m.start()); blk = text[ob + 1:match_close(text, ob)]
            im = re.search(r"^\s*id:\s*(\w+)", blk, re.M)
            if im:
                for r in re.finditer(r"\b" + im.group(1) + r"\.(\w+)", text):
                    if r.group(1) not in ITEM_PROPS: props.add(r.group(1))
        props = {p for p in props if p not in ITEM_PROPS}
        sigs = "".join("    signal %s()\n" % (h[0].lower() + h[1:]) for h in handlers if not h.endswith("Changed"))
        decl = "".join("    property var %s\n" % p for p in sorted(props))
        base = "Text" if T == "Label" else "Item"
        if T == "Label": decl = decl.replace("    property var text\n", "").replace("    property var color\n", "").replace("    property var elide\n", "").replace("    property var wrapMode\n", "").replace("    property var horizontalAlignment\n", "").replace("    property var verticalAlignment\n", "").replace("    property var maximumLineCount\n", "").replace("    property var textFormat\n", "")
        if T == "Anim": base, decl, sigs = "NumberAnimation", "", ""
        if T == "ColorAnim": base, decl, sigs = "ColorAnimation", "", ""
        body = "import QtQuick\n%s {\n%s%s}\n" % (base, decl, sigs)
        target = H / "shell/modules/island" / (T + ".qml") if T in island_dir else H / "shell/components" / (T + ".qml")
        target.write_text(body)
        if T not in island_dir: comp_lines.append("%s 1.0 %s.qml" % (T, T))
    (H / "shell/components/qmldir").write_text("module qs.components\n" + "\n".join(comp_lines) + "\n")

CONFIG_STUB = """pragma Singleton
import QtQuick
import "ControlLayout.js" as ControlLayout
QtObject {
    id: cfg
    property var control: ({ width: 480, hidden: [], custom: false, sections: "media,tiles,sliders,stats,calendar,notifications",
                             tiles: "wifi,bluetooth,night,awake,mic,vpn" })
    readonly property var controlSections: ControlLayout.clean(control.sections, ControlLayout.sections, ControlLayout.defaultSections)
    readonly property var controlTiles: ControlLayout.clean(control.tiles, ControlLayout.tiles, ControlLayout.defaultTiles)
    property var maxVolume: 1.0
    property var nightLight: ({ enabled: false })
    property var theme: ({ flavor: "mocha", darkFlavor: "mocha" })
    property var bar: ({ clockFormat: "HH:mm" })
    function controlShows(id) { return !control.hidden.includes(id); }
    function saveSoon() {}
}
"""
SVC_DEFAULTS = {("Accounts", "self"): '({ full: "Erox", name: "erox" })', ("Distro", "label"): '"Eroxis V.0.1.1"', ("Distro", "host"): '"CachyOS"', ("Chrono", "timerActive"): "false", ("Panels", "controlOpen"): "false", ("Brightness", "available"): "false", ("Brightness", "value"): "0.5",
                ("Media", "active"): "null", ("SystemStats", "cpu"): "0.2", ("SystemStats", "memory"): "0.4", ("SystemStats", "disk"): "0.5",
                ("SystemStats", "temperature"): "40", ("KeepAwake", "active"): "false", ("NightLight", "active"): "false",
                ("NoiseSuppression", "level"): "0", ("NoiseSuppression", "labels"): "[]"}

TEST = """import QtQuick
import QtTest
import qs.config
TestCase {
    id: tc
    name: "ControlView"
    when: windowShown
    width: 800; height: 900
    Component { id: hostC; Item { width: 800; height: 900 } }
    function test_scenario() {
        Config.control = %(config)s;
        const comp = Qt.createComponent("file://@H@/shell/modules/island/ControlView.qml");
        compare(comp.status, Component.Ready, "did not load: " + comp.errorString());
        const host = createTemporaryObject(hostC, tc);
        const cv = comp.createObject(host, {});
        verify(cv !== null, "could not create");
        wait(400);
        %(extra)s
        console.log("RESULT custom=" + cv.custom + " width=" + cv.width + " hang=" + cv.hang);
        verify(isFinite(cv.hang) && cv.hang > 0, "hang is " + cv.hang);
        verify(isFinite(cv.width) && cv.width > 0, "width is " + cv.width);
        %(expect)s
        const h1 = cv.hang; wait(300); compare(cv.hang, h1, "size keeps changing");
        cv.destroy();
    }
}
"""

def scenario(name, config, expect="", extra=""):
    (H / "tst_control.qml").write_text((TEST % {"config": config, "expect": expect, "extra": extra}).replace("@H@", str(H)))
    env = dict(os.environ, QT_QPA_PLATFORM="offscreen", QML2_IMPORT_PATH=str(H))
    p = subprocess.run([os.environ.get("QMLTESTRUNNER", "/usr/lib/qt6/bin/qmltestrunner"), "-input", str(H / "tst_control.qml"), "-import", str(H)], env=env, capture_output=True, text=True, timeout=120)
    out = p.stdout + p.stderr
    warn = sorted(set(re.sub(r"file://@H@/shell/|:\d+(:\d+)?", "", l.strip()) for l in out.split("\n") if re.search(r"Warning|QWARN|Error|loop|recursive|Unable|Cannot", l) and "Totals" not in l))
    res = [l for l in out.split("\n") if "RESULT" in l]
    fail = [l for l in out.split("\n") if l.startswith("FAIL")]
    return {"name": name, "ok": p.returncode == 0, "result": res[-1].split("RESULT ")[-1] if res else "-", "fail": fail, "warn": warn}


