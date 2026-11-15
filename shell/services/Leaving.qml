pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

Singleton {
    id: root

    property string mode: ""
    property string command: ""

    function run(kind, cmd) {
        if (mode) return;
        mode = kind;
        command = cmd;
        go.restart();
    }

    function preview(kind) {
        mode = kind;
        command = "";
        endPreview.restart();
    }
    Timer { id: endPreview; interval: 3000; onTriggered: root.mode = "" }

    Timer {
        id: go
        interval: 1100
        onTriggered: Quickshell.execDetached(["sh", "-c",
            'touch "${XDG_RUNTIME_DIR:-/tmp}/eroxis-leaving"; ' + root.command])
    }
    Timer {
        running: root.mode !== ""
        interval: 20000
        onTriggered: {
            Quickshell.execDetached(["sh", "-c", 'rm -f "${XDG_RUNTIME_DIR:-/tmp}/eroxis-leaving"']);
            root.mode = "";
        }
    }
}
