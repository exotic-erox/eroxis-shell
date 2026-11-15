pragma Singleton
import Quickshell
import Quickshell.Bluetooth
import QtQuick

Singleton {
    id: root
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false

    function setEnabled(on) {
        if (!adapter) return;
        if (!on) {
            adapter.enabled = false;
            Quickshell.execDetached(["rfkill", "block", "bluetooth"]);
            return;
        }
        Quickshell.execDetached(["rfkill", "unblock", "bluetooth"]);
        powerOn.restart();
    }
    function toggle() { setEnabled(!enabled); }
    Timer { id: powerOn; interval: 400; onTriggered: if (root.adapter) root.adapter.enabled = true }
}
