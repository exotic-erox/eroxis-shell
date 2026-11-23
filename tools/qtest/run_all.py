# SPDX-License-Identifier: GPL-3.0-or-later
"""Runs the control center through its layouts in a headless Qt runtime (qml6-module-qtquick, -layouts, -qttest and
qmltestrunner needed; QT_QPA_PLATFORM=offscreen is set for you). Exit code 1 if any scenario fails.
Run: python3 tools/qtest/run_all.py"""
import re
import sys, json, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import harness as h
SHELL = h.SHELL
base = {"width": 480, "hidden": [], "custom": False, "sections": "media,tiles,sliders,stats,calendar,notifications", "tiles": "wifi,bluetooth,night,awake,mic,vpn"}
def cfg(**kw): d = dict(base); d.update(kw); return json.dumps(d)
ALLS = "media,tiles,sliders,stats,calendar,notifications,clock,greeting,emblem"
ALLT = "wifi,bluetooth,night,awake,mic,vpn,dnd,airplane,dark,profile,screenshot,picker,clipboard,timer,wallpaper,lock"
custom = SHELL / "modules/island/ControlCustom.qml"
h.build(SHELL / "modules/island/ControlView.qml", companions=[custom])
runs = [
 ("classic", cfg(), "verify(!cv.custom, 'should be classic')"),
 ("custom, default lists", cfg(custom=True), "verify(cv.custom, 'should be custom')"),
 ("custom, every section and tile", cfg(custom=True, sections=ALLS, tiles=ALLT), "verify(cv.custom)"),
 ("custom, empty lists", cfg(custom=True, sections="", tiles=""), "verify(cv.custom)"),
 ("custom, garbage lists", cfg(custom=True, sections="nope,tiles,tiles,5", tiles=5), "verify(cv.custom)"),
 ("custom, wide", cfg(custom=True, width=640, sections=ALLS, tiles=ALLT), "verify(cv.custom)"),
 ("custom, reordered", cfg(custom=True, sections="notifications,emblem,tiles,clock", tiles="lock,wifi,dnd"), "verify(cv.custom)"),
]
extra_switch = "Config.control = Object.assign({}, Config.control, { custom: !Config.control.custom }); wait(300); Config.control = Object.assign({}, Config.control, { custom: !Config.control.custom }); wait(300); Config.control = Object.assign({}, Config.control, { sections: 'clock,tiles', custom: true}); wait(300); Config.control = Object.assign({}, Config.control, { sections: 'tiles,clock,media' }); wait(300);"
res = [h.scenario(n, c, e) for n, c, e in runs]
res.append(h.scenario("switching live", cfg(custom=True, sections=ALLS, tiles=ALLT), "verify(cv.custom)", extra_switch))
# a custom layout file that cannot be loaded: the classic panel has to stay
(h.H / "shell/modules/island/ControlCustom.qml").write_text("import QtQuick\nItem { this is not valid qml }\n")
res.append(h.scenario("classic, with a broken custom file present", cfg(), "verify(!cv.custom)"))
res.append(h.scenario("custom file broken -> falls back", cfg(custom=True), "verify(!cv.custom, 'should fall back to the classic panel')"))
(h.H / "shell/modules/island/ControlCustom.qml").unlink()
res.append(h.scenario("custom file missing -> falls back", cfg(custom=True), "verify(!cv.custom, 'should fall back to the classic panel')"))
base_warn = set(res[0]["warn"])
for r in res:
    new = [w for w in r["warn"] if re.sub(r"\(0x[0-9a-f]+\)", "", w) not in {re.sub(r"\(0x[0-9a-f]+\)", "", b) for b in base_warn}]
    print(("PASS" if r["ok"] else "FAIL"), "|", r["name"], "|", r["result"])
    for f in r["fail"]: print("     ", f[:200])
    for w in new[:6]: print("      new warning:", w[:170])
print("\nbaseline (classic) warnings, from stand-ins:", len(base_warn))

sys.exit(0 if all(r["ok"] for r in res) else 1)
