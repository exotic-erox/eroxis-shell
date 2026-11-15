import QtQuick
import QtQuick.Controls.Basic as C
import qs.config

// A slim scroll bar for a Flickable: always there when the content is longer than the view, quiet until you point at it,
// and you can drag it. Use it as  C.ScrollBar.vertical: SlimScrollBar {}  (import QtQuick.Controls.Basic as C).
C.ScrollBar {
    id: bar
    policy: size < 1 ? C.ScrollBar.AlwaysOn : C.ScrollBar.AlwaysOff
    interactive: true
    minimumSize: 0.08
    padding: 3
    implicitWidth: 14

    contentItem: Rectangle {
        implicitWidth: bar.pressed || bar.hovered ? 7 : 4
        radius: width / 2
        color: bar.pressed ? Theme.accent : Theme.overlay1
        opacity: bar.pressed ? 1 : bar.hovered ? 0.9 : 0.4
        Behavior on implicitWidth { NumberAnimation { duration: 100 } }
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
    background: Item {}
}
