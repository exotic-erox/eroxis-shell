import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

SettingsPage {
    pageId: "controlcenter"

    component Part: SettingsRow {
        id: part
        required property string key
        Switch { checked: Config.controlShows(part.key); onToggled: on => Config.controlToggle(part.key, on) }
    }

    SettingsRow {
        title: Tr.t("Width")
        Choice {
            options: [{ value: 420, label: Tr.t("Narrow") }, { value: 480, label: Tr.t("Normal") }, { value: 560, label: Tr.t("Wide") }, { value: 640, label: Tr.t("Wider") }]
            current: Config.control.width
            onPicked: v => { Config.control.width = v; Config.saveSoon(); }
        }
    }

    SettingsSection { text: Tr.t("Show") }
    Part { title: Tr.t("Now playing"); key: "media" }
    Part { title: Tr.t("Wi-Fi"); key: "wifi" }
    Part { title: Tr.t("Bluetooth"); key: "bluetooth" }
    Part { title: Tr.t("Night light"); key: "night" }
    Part { title: Tr.t("Keep awake"); key: "awake" }
    Part { title: Tr.t("Microphone"); key: "mic" }
    Part { title: Tr.t("VPN"); key: "vpn" }
    Part { title: Tr.t("Volume and brightness"); key: "sliders" }
    Part { title: Tr.t("CPU, memory and disk"); key: "stats" }
    Part { title: Tr.t("Weather and calendar"); key: "calendar" }
    Part { title: Tr.t("Notifications"); key: "notifications" }
}
