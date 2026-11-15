import QtQuick
import QtQuick.Window
import qs.config
import "LogoShape.js" as LogoShape
import "LogoArt.js" as LogoArt

// The Eroxis emblem: an E in an orbit, with a star. Small, it is the icon; large, it is drawn from its path, the star
// apart so it can twinkle when `animated`.
Item {
    id: root
    property real size: 84
    property bool animated: false
    property var colors: Theme.palette
    property string accentName: Theme.accentName
    property color accent: LogoArt.accent(colors, accentName)
    property color partner: LogoArt.partner(colors, accentName)
    property color base: colors.base

    implicitWidth: size
    implicitHeight: size

    readonly property var shape: LogoShape.shape
    readonly property bool small: size < 40
    readonly property real dpr: Screen.devicePixelRatio || 1
    // the emblem is wider than tall: its width fills `size`
    readonly property real k: size / shape.viewBox[2]

    function hex(c) {
        return Qt.rgba(c.r, c.g, c.b, 1).toString();
    }
    function uri(viewBox, d, px) {
        return "data:image/svg+xml;charset=utf-8," + encodeURIComponent(LogoArt.art(viewBox, d, hex(accent), px));
    }

    Icon {
        visible: root.small
        name: "eroxis"
        size: root.size
        color: root.accent
    }

    Item {
        id: art
        visible: !root.small
        width: root.size
        height: root.shape.viewBox[3] * root.k
        anchors.centerIn: parent

        Image {
            width: art.width
            height: art.height
            sourceSize: Qt.size(Math.ceil(art.width * root.dpr), Math.ceil(art.height * root.dpr))
            source: art.visible ? root.uri(root.shape.viewBox.join(" "), root.shape.body, Math.ceil(art.width * root.dpr)) : ""
        }

        Image {
            id: star
            readonly property var box: root.shape.starBox
            x: (box[0] - root.shape.viewBox[0]) * root.k
            y: (box[1] - root.shape.viewBox[1]) * root.k
            width: box[2] * root.k
            height: box[3] * root.k
            transformOrigin: Item.Center
            sourceSize: Qt.size(Math.ceil(width * root.dpr), Math.ceil(height * root.dpr))
            source: art.visible ? root.uri(box.join(" "), root.shape.star, Math.ceil(width * root.dpr)) : ""

            SequentialAnimation {
                running: root.animated && art.visible
                loops: Animation.Infinite
                ParallelAnimation {
                    NumberAnimation { target: star; property: "scale"; to: 1.18; duration: 900; easing.type: Easing.InOutSine }
                    NumberAnimation { target: star; property: "opacity"; to: 1; duration: 900; easing.type: Easing.InOutSine }
                }
                ParallelAnimation {
                    NumberAnimation { target: star; property: "scale"; to: 0.78; duration: 1100; easing.type: Easing.InOutSine }
                    NumberAnimation { target: star; property: "opacity"; to: 0.55; duration: 1100; easing.type: Easing.InOutSine }
                }
                onRunningChanged: if (!running) { star.scale = 1; star.opacity = 1; }
            }
        }
    }
}
