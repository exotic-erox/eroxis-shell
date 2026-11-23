import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services
import "../../../config/ControlLayout.js" as ControlLayout

SettingsPage {
    id: page
    pageId: "controlcenter"

    readonly property var sectionNames: ({
        media: Tr.t("Now playing"), tiles: Tr.t("Tiles"), sliders: Tr.t("Volume and brightness"),
        stats: Tr.t("CPU, memory and disk"), calendar: Tr.t("Weather and calendar"), notifications: Tr.t("Notifications"),
        clock: Tr.t("Clock"), greeting: Tr.t("Greeting"), emblem: Tr.t("Emblem")
    })
    readonly property var tileNames: ({
        wifi: Tr.t("Wi-Fi"), bluetooth: Tr.t("Bluetooth"), night: Tr.t("Night light"), awake: Tr.t("Keep awake"),
        mic: Tr.t("Microphone"), vpn: Tr.t("VPN"), dnd: Tr.t("Do not disturb"), airplane: Tr.t("Airplane mode"),
        dark: Tr.t("Dark mode"), profile: Tr.t("Power mode"), screenshot: Tr.t("Screenshot"), picker: Tr.t("Color picker"),
        clipboard: Tr.t("Clipboard"), timer: Tr.t("Timer"), wallpaper: Tr.t("Wallpapers"), lock: Tr.t("Lock")
    })
    // the ones that are on, in their order, then the ones that are off
    readonly property var allSections: Config.controlSections.concat(ControlLayout.sections.filter(k => !Config.controlSections.includes(k)))
    readonly property var allTiles: Config.controlTiles.concat(ControlLayout.tiles.filter(k => !Config.controlTiles.includes(k)))
    readonly property bool custom: Config.control.custom

    // Classic layout: a switch to show or hide a part.
    component Part: SettingsRow {
        id: part
        required property string key
        Switch { checked: Config.controlShows(part.key); onToggled: on => Config.controlToggle(part.key, on) }
    }

    // Custom layout: a switch for showing it, and arrows to move it (when it is on).
    component Entry: SettingsRow {
        id: entry
        required property string list
        required property string key
        readonly property var current: list === "tiles" ? Config.controlTiles : Config.controlSections
        readonly property bool shown: current.includes(key)
        readonly property int at: current.indexOf(key)

        RowLayout {
            spacing: Theme.space6
            ChipButton {
                visible: entry.shown
                opacity: entry.at > 0 ? 1 : 0.3
                text: "\u2191"
                onClicked: Config.controlMove(entry.list, entry.key, -1)
            }
            ChipButton {
                visible: entry.shown
                opacity: entry.at < entry.current.length - 1 ? 1 : 0.3
                text: "\u2193"
                onClicked: Config.controlMove(entry.list, entry.key, 1)
            }
            Switch { checked: entry.shown; onToggled: on => Config.controlSet(entry.list, entry.key, on) }
        }
    }

    SettingsRow {
        title: Tr.t("Layout")
        Choice {
            options: [{ value: "classic", label: Tr.t("Classic") }, { value: "custom", label: Tr.t("Custom (beta)") }]
            current: page.custom ? "custom" : "classic"
            onPicked: v => { Config.control.custom = (v === "custom"); Config.saveSoon(); }
        }
    }
    Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: Theme.subtext0
        text: page.custom
            ? Tr.t("Choose what the control center shows and in what order, and add more tiles. If it ever looks wrong, switch back to Classic here, or run eroxis-reset-layout in a terminal.")
            : Tr.t("Classic is the usual control center. Switch to Custom to put it in your own order and add more tiles.")
    }

    SettingsRow {
        title: Tr.t("Width")
        Choice {
            options: [{ value: 420, label: Tr.t("Narrow") }, { value: 480, label: Tr.t("Normal") }, { value: 560, label: Tr.t("Wide") }, { value: 640, label: Tr.t("Wider") }]
            current: ControlLayout.width(Config.control.width)
            onPicked: v => { Config.control.width = v; Config.saveSoon(); }
        }
    }

    // ---- classic
    SettingsSection { visible: !page.custom; text: Tr.t("Show") }
    Part { visible: !page.custom; title: Tr.t("Now playing"); key: "media" }
    Part { visible: !page.custom; title: Tr.t("Wi-Fi"); key: "wifi" }
    Part { visible: !page.custom; title: Tr.t("Bluetooth"); key: "bluetooth" }
    Part { visible: !page.custom; title: Tr.t("Night light"); key: "night" }
    Part { visible: !page.custom; title: Tr.t("Keep awake"); key: "awake" }
    Part { visible: !page.custom; title: Tr.t("Microphone"); key: "mic" }
    Part { visible: !page.custom; title: Tr.t("VPN"); key: "vpn" }
    Part { visible: !page.custom; title: Tr.t("Volume and brightness"); key: "sliders" }
    Part { visible: !page.custom; title: Tr.t("CPU, memory and disk"); key: "stats" }
    Part { visible: !page.custom; title: Tr.t("Weather and calendar"); key: "calendar" }
    Part { visible: !page.custom; title: Tr.t("Notifications"); key: "notifications" }

    // ---- custom
    SettingsSection { visible: page.custom; text: Tr.t("Order and what shows") }
    Repeater {
        model: page.custom ? page.allSections : []
        delegate: Entry {
            required property string modelData
            list: "sections"
            key: modelData
            title: page.sectionNames[modelData]
        }
    }
    SettingsSection { visible: page.custom; text: Tr.t("Tiles") }
    Repeater {
        model: page.custom ? page.allTiles : []
        delegate: Entry {
            required property string modelData
            list: "tiles"
            key: modelData
            title: page.tileNames[modelData]
        }
    }

    SettingsRow {
        title: Tr.t("Back to the default layout")
        ChipButton { text: Tr.t("Reset"); onClicked: Config.controlReset() }
    }
}
