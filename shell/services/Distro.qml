pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // This shell.
    readonly property string name: "Eroxis"
    readonly property string version: "0.1.0"
    readonly property string glyph: "eroxis"
    readonly property string label: name + " V." + version

    // The system underneath it (Arch, CachyOS, ...), from /etc/os-release.
    property string host: "Linux"

    FileView {
        path: "/etc/os-release"
        printErrors: false
        onLoaded: {
            const m = text().match(/^PRETTY_NAME="?([^"\n]*)"?/m);
            if (m) root.host = m[1];
        }
    }
}
