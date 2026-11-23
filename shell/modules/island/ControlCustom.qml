import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import "../../components/Icons.js" as Icons
import qs.services
// The control center in the order, and of the parts, Settings > Control center chose. It is loaded by ControlView only when
// the custom layout is on, and if it does not load ControlView keeps showing the classic one.
PanelBody {
    id: body
    readonly property var host: island
    spacing: Theme.space10

    component Card: Item {
        id: card
        default property alias content: inner.data
        property real pad: 4
        property alias spacing: inner.spacing
        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight + pad * 2
        ColumnLayout {
            id: inner
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: parent.pad }
            spacing: Theme.space12
        }
    }

    component Gauge: Item {
        id: g
        property alias value: ring.value
        property alias text: ring.text
        property alias caption: ring.caption
        property alias color: ring.color
        signal clicked()
        Layout.fillWidth: true
        implicitHeight: 62
        Ring { id: ring; anchors.centerIn: parent; scale: gArea.containsMouse ? 1.06 : 1; Behavior on scale { Anim { duration: Theme.durationFast } } }
        PressArea { label: ring.caption + " " + ring.text; id: gArea; anchors.fill: parent; onClicked: g.clicked() }
    }

    function tileComponent(id) {
        return ({ wifi: tile_wifi, bluetooth: tile_bluetooth, night: tile_night, awake: tile_awake, mic: tile_mic, vpn: tile_vpn,
                  dnd: tile_dnd, airplane: tile_airplane, dark: tile_dark, profile: tile_profile, screenshot: tile_screenshot,
                  picker: tile_picker, clipboard: tile_clipboard, timer: tile_timer, wallpaper: tile_wallpaper, lock: tile_lock })[id] ?? null;
    }
    function sectionComponent(id) {
        return ({ media: sec_media, tiles: sec_tiles, sliders: sec_sliders, stats: sec_stats, calendar: sec_calendar,
                  notifications: sec_notes, clock: sec_clock, greeting: sec_greeting, emblem: sec_emblem })[id] ?? null;
    }

    Repeater {
        model: Config.controlSections
        delegate: Loader {
            id: slot
            required property string modelData
            Layout.fillWidth: true
            sourceComponent: body.sectionComponent(modelData)
            visible: item ? (item.wanted ?? true) : false
            onLoaded: item.width = Qt.binding(() => slot.width)
        }
    }

    Component {
        id: sec_media
        Rectangle {
            id: mediaCard
            readonly property var player: Media.active
            readonly property bool wanted: player !== null
            implicitHeight: mediaRow.implicitHeight + 24
            color: "transparent"

            Timer {
                running: body.host.active && mediaCard.player !== null
                interval: 1000
                repeat: true
                triggeredOnStart: true
                onTriggered: mediaCard.player?.positionChanged()
            }
            property real knownLength: 0
            readonly property real length: (player?.lengthSupported && player.length > 0) ? player.length : knownLength
            onLengthChanged: if (player?.lengthSupported && player.length > 0) knownLength = player.length
            Connections {
                target: mediaCard.player
                function onTrackTitleChanged() { mediaCard.knownLength = 0; }
            }

            RowLayout {
                id: mediaRow
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: Theme.space12; rightMargin: Theme.space12 }
                spacing: Theme.space12

                ClippingRectangle {
                    implicitWidth: 52; implicitHeight: 52; radius: Theme.r(12)
                    color: Theme.accent
                    Image {
                        anchors.fill: parent
                        source: mediaCard.player?.trackArtUrl ?? ""
                        sourceSize: Qt.size(104, 104)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }
                    Icon { anchors.centerIn: parent; visible: !(mediaCard.player?.trackArtUrl); name: "music"; size: 22; color: Theme.textOnAccent }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.space4
                    Label {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.weight: Font.DemiBold
                        text: mediaCard.player?.trackTitle || mediaCard.player?.identity || ""
                    }
                    Label {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.overlay1
                        text: mediaCard.player?.trackArtist || mediaCard.player?.identity || ""
                    }
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 10
                        opacity: mediaCard.length > 0 ? 1 : 0.4
                        Row {
                            id: progCells
                            anchors.fill: parent
                            readonly property int count: 22
                            readonly property int lit: mediaCard.length > 0 ? Math.round(Math.max(0, Math.min(1, (mediaCard.player?.position ?? 0) / mediaCard.length)) * count) : 0
                            spacing: Theme.space4
                            Repeater {
                                model: progCells.count
                                Rectangle {
                                    required property int index
                                    readonly property bool on: index < progCells.lit
                                    width: (progCells.width - (progCells.count - 1) * progCells.spacing) / progCells.count
                                    height: on ? 8 : 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: 2
                                    color: !on ? Theme.tint(parent, Theme.text, 0.12) : index === progCells.lit - 1 ? Theme.accentBright : Theme.accent
                                    Behavior on height { Anim { duration: Theme.durationFast } }
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            enabled: (mediaCard.player?.canSeek ?? false) && mediaCard.length > 0
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: mouse => mediaCard.player.position = Math.max(0, Math.min(1, mouse.x / width)) * mediaCard.length
                        }
                    }
                }

                Row {
                    spacing: Theme.space4
                    IconButton { size: 30; anchors.verticalCenter: parent.verticalCenter; icon: "previous"; label: Tr.t("Previous"); active: mediaCard.player?.canGoPrevious ?? false; onClicked: mediaCard.player.previous() }
                    IconButton { anchors.verticalCenter: parent.verticalCenter; primary: true; size: 38; icon: mediaCard.player?.isPlaying ? "pause" : "play"; label: mediaCard.player?.isPlaying ? Tr.t("Pause") : Tr.t("Play"); active: mediaCard.player?.canTogglePlaying ?? false; onClicked: mediaCard.player.togglePlaying() }
                    IconButton { size: 30; anchors.verticalCenter: parent.verticalCenter; icon: "next"; label: Tr.t("Next"); active: mediaCard.player?.canGoNext ?? false; onClicked: mediaCard.player.next() }
                }
            }
        }
    }

    Component {
        id: sec_tiles
        GridLayout {
            readonly property bool wanted: Config.controlTiles.length > 0
            columns: Config.control.width >= 560 ? 3 : 2
            rowSpacing: 8
            columnSpacing: 8
            Repeater {
                model: Config.controlTiles
                delegate: Loader {
                    id: tileSlot
                    required property string modelData
                    Layout.fillWidth: true
                    sourceComponent: body.tileComponent(modelData)
                    onLoaded: item.width = Qt.binding(() => tileSlot.width)
                }
            }
        }
    }

    Component {
        id: sec_sliders
        Card {
            SegmentSlider {
                Layout.fillWidth: true
                Layout.topMargin: Theme.space2
                icon: body.host.sink?.audio?.muted ? "volume-x" : "volume"
                label: Tr.t("Volume")
                iconLabel: Tr.t("Mute")
                iconLevel: Icons.volumeLevel(body.host.sink?.audio?.volume ?? 0)
                value: body.host.sink?.audio?.volume ?? 0
                maximum: Config.maxVolume
                dimmed: body.host.sink?.audio?.muted ?? false
                valueText: body.host.sink?.audio?.muted ? "--" : Math.round(level * 100)
                onMoved: v => { if (body.host.sink?.audio) body.host.sink.audio.volume = v; }
                onIconClicked: if (body.host.sink?.audio) body.host.sink.audio.muted = !body.host.sink.audio.muted
            }
            SegmentSlider {
                Layout.fillWidth: true
                visible: Brightness.available
                icon: "sun"
                label: Tr.t("Brightness")
                value: Brightness.value
                onMoved: v => Brightness.set(v)
            }
        }
    }

    Component {
        id: sec_stats
        Card {
            pad: 8
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                function tint(v) { return v > 0.9 ? Theme.error : v > 0.75 ? Theme.warning : Theme.accent; }

                Gauge {
                    value: SystemStats.cpu
                    color: parent.tint(SystemStats.cpu)
                    text: Math.round(SystemStats.cpu * 100)
                    caption: Tr.t("CPU")
                    onClicked: Panels.systemOpen = true
                }
                Gauge {
                    value: SystemStats.memory
                    color: parent.tint(SystemStats.memory)
                    text: Math.round(SystemStats.memory * 100)
                    caption: Tr.t("RAM")
                    onClicked: Panels.systemOpen = true
                }
                Gauge {
                    visible: SystemStats.temperature >= 0
                    value: SystemStats.temperature / 100
                    color: SystemStats.temperature > 85 ? Theme.error : SystemStats.temperature > 70 ? Theme.warning : Theme.accent
                    text: Math.round(SystemStats.temperature)
                    caption: "°C"
                    onClicked: Panels.systemOpen = true
                }
                Gauge {
                    value: SystemStats.disk
                    color: parent.tint(SystemStats.disk)
                    text: Math.round(SystemStats.disk * 100)
                    caption: Tr.t("Disk")
                    onClicked: Panels.systemOpen = true
                }
            }
        }
    }

    Component {
        id: sec_calendar
        Card {
            pad: 12
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space12
                TodayWeather {
                    Layout.fillWidth: true
                    Layout.minimumWidth: Theme.fontSize * 7
                    Layout.leftMargin: Theme.space4
                    titleY: calendar.titleY
                    datesBaseline: calendar.datesBaseline
                }
                MonthCalendar {
                    id: calendar
                    Layout.alignment: Qt.AlignTop; Layout.fillWidth: true; Layout.maximumWidth: implicitWidth
                    marked: d => Calendar.on(d).length > 0
                    onDayClicked: d => { Panels.controlOpen = false; Panels.openApp("calendar", "open", Calendar.key(d)); }
                }
            }

            Connections { target: body.host; function onActiveChanged() { if (body.host.active) calendar.reset(); } }
            Component.onCompleted: if (body.host.active) calendar.reset()
        }
    }

    Component {
        id: sec_notes
        ColumnLayout {
            spacing: Theme.space10
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.hairlineOn(parent) }
            NotificationList {
                Layout.fillWidth: true
                maxListHeight: 240
            }
        }
    }

    Component {
        id: sec_clock
        Card {
            SystemClock { id: tick; precision: SystemClock.Minutes }
            Label {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 46
                font.weight: Font.Light
                text: Qt.formatTime(tick.date, "HH:mm")
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                color: Theme.subtext0
                text: Qt.formatDate(tick.date, "dddd, d MMMM")
            }
        }
    }
    Component {
        id: sec_greeting
        Card {
            SystemClock { id: tick; precision: SystemClock.Minutes }
            readonly property int hour: tick.date.getHours()
            Label {
                Layout.fillWidth: true
                font.pixelSize: 20
                font.weight: Font.DemiBold
                text: (hour < 5 ? Tr.t("Good night") : hour < 12 ? Tr.t("Good morning") : hour < 18 ? Tr.t("Good afternoon") : Tr.t("Good evening")) + ", " + (Accounts.self.full || Accounts.self.name)
            }
            Label {
                Layout.fillWidth: true
                color: Theme.subtext0
                text: Distro.label + "  \u00b7  " + Distro.host
            }
        }
    }
    Component {
        id: sec_emblem
        Card {
            Logo { Layout.alignment: Qt.AlignHCenter; size: 104; animated: body.host.active }
            Label { Layout.alignment: Qt.AlignHCenter; color: Theme.subtext0; text: Distro.label }
        }
    }

    Component {
        id: tile_wifi
            QuickTile {
                icon: Networking.wifiEnabled ? "wifi" : "wifi-off"
                title: Tr.t("Wi-Fi")
                subtitle: !Networking.wifiEnabled ? Tr.t("Off") : body.host.wifiNetwork?.name ?? Tr.t("Not connected")
                on: Networking.wifiEnabled
                enabled: body.host.wifi !== null
                more: true
                onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                onMoreClicked: Panels.wifiOpen = true
            }
    }
    Component {
        id: tile_bluetooth
            QuickTile {
                icon: "bluetooth"
                title: Tr.t("Bluetooth")
                subtitle: !(body.host.adapter?.enabled ?? false) ? Tr.t("Off")
                    : body.host.btConnected.length === 1 ? (body.host.btConnected[0].name || body.host.btConnected[0].deviceName || Tr.t("1 device"))
                    : body.host.btConnected.length > 1 ? Tr.f("{0} devices", body.host.btConnected.length) : Tr.t("On")
                on: body.host.adapter?.enabled ?? false
                enabled: body.host.adapter !== null
                more: true
                onClicked: BluetoothCtl.toggle()
                onMoreClicked: Panels.bluetoothOpen = true
            }
    }
    Component {
        id: tile_night
            QuickTile {
                icon: "sunset"
                title: Tr.t("Night light")
                subtitle: NightLight.active ? Config.nightLight.temperature + Tr.t(" K")
                    : Config.nightLight.automatic ? Tr.f("From {0}", Config.nightLight.start) : Tr.t("Off")
                on: NightLight.active
                more: true
                onClicked: NightLight.toggle()
                onMoreClicked: Panels.nightOpen = true
            }
    }
    Component {
        id: tile_awake
            QuickTile {
                icon: KeepAwake.icon
                title: Tr.t("Keep awake")
                subtitle: !KeepAwake.active ? Tr.t("Off")
                    : (KeepAwake.inhibitDisplay ? Tr.t("Screen stays on") : Tr.t("System stays on")) + (KeepAwake.minutes > 0 ? ", " + KeepAwake.minutes + Tr.t(" min") : "")
                on: KeepAwake.active
                more: true
                onClicked: KeepAwake.toggle()
                onMoreClicked: Panels.awakeOpen = true
            }
    }
    Component {
        id: tile_mic
            QuickTile {
                icon: body.host.source?.audio?.muted ? "mic-off" : "mic"
                title: Tr.t("Microphone")
                subtitle: body.host.source?.audio?.muted ?? true ? Tr.t("Muted")
                    : NoiseSuppression.level > 0 ? Tr.f("Noise {0}", NoiseSuppression.labels[NoiseSuppression.level].toLowerCase()) : body.host.nodeName(body.host.source)
                on: !(body.host.source?.audio?.muted ?? true)
                enabled: body.host.source !== null
                more: true
                onClicked: body.host.source.audio.muted = !body.host.source.audio.muted
                onMoreClicked: Panels.soundOpen = true
            }
    }
    Component {
        id: tile_vpn
            QuickTile {
                icon: "vpn"
                title: Tr.t("VPN")
                subtitle: Vpn.active ? (Vpn.active.place || Vpn.active.name) : Tr.t("Off")
                on: Vpn.active !== null
                more: true
                onClicked: { if (Vpn.list.length > 0 || Vpn.places.length > 0) Vpn.quick(); else Panels.vpnOpen = true; }
                onMoreClicked: Panels.vpnOpen = true
            }
    }

    Component {
        id: tile_dnd
        QuickTile {
            icon: Notifications.dnd ? "bell-off" : "bell"
            title: Tr.t("Do not disturb")
            subtitle: Notifications.dnd ? Tr.t("On") : Tr.t("Off")
            on: Notifications.dnd
            onClicked: Notifications.dnd = !Notifications.dnd
        }
    }
    Component {
        id: tile_airplane
        QuickTile {
            icon: Hardware.airplane ? "airplane" : "airplane-off"
            title: Tr.t("Airplane mode")
            subtitle: Hardware.airplane ? Tr.t("On") : Tr.t("Off")
            on: Hardware.airplane
            onClicked: Hardware.toggleAirplane()
        }
    }
    Component {
        id: tile_dark
        QuickTile {
            readonly property bool dark: Config.theme.flavor !== "latte"
            icon: dark ? "moon" : "sun"
            title: Tr.t("Dark mode")
            subtitle: dark ? Tr.t("On") : Tr.t("Off")
            on: dark
            onClicked: { Config.theme.flavor = dark ? "latte" : (Config.theme.darkFlavor || "mocha"); Config.saveSoon(); }
        }
    }
    Component {
        id: tile_profile
        QuickTile {
            icon: Power.profile === PowerProfile.PowerSaver ? "power-saver" : Power.profile === PowerProfile.Performance ? "power-performance" : "power-balanced"
            title: Tr.t("Power mode")
            subtitle: Power.profile === PowerProfile.PowerSaver ? Tr.t("Power saver") : Power.profile === PowerProfile.Performance ? Tr.t("Performance") : Tr.t("Balanced")
            on: Power.profile !== PowerProfile.Balanced
            onClicked: Power.set(Power.profile === PowerProfile.PowerSaver ? PowerProfile.Balanced : Power.profile === PowerProfile.Balanced ? PowerProfile.Performance : PowerProfile.PowerSaver)
        }
    }
    Component {
        id: tile_screenshot
        QuickTile {
            icon: "camera"
            title: Tr.t("Screenshot")
            subtitle: Tr.t("Select a region")
            onClicked: { Panels.controlOpen = false; Screenshot.capture("region"); }
        }
    }
    Component {
        id: tile_picker
        QuickTile {
            icon: "palette"
            title: Tr.t("Color picker")
            subtitle: Tr.t("Copies the color")
            onClicked: { Panels.controlOpen = false; Quickshell.execDetached(["hyprpicker", "-a"]); }
        }
    }
    Component {
        id: tile_clipboard
        QuickTile {
            icon: "clipboard"
            title: Tr.t("Clipboard")
            subtitle: Tr.t("History")
            onClicked: Panels.search(":")
        }
    }
    Component {
        id: tile_timer
        QuickTile {
            icon: "timer"
            title: Tr.t("Timer")
            subtitle: Chrono.timerActive ? Tr.t("Running") : Tr.t("Timer and stopwatch")
            on: Chrono.timerActive
            onClicked: Panels.timerOpen = true
        }
    }
    Component {
        id: tile_wallpaper
        QuickTile {
            icon: "image"
            title: Tr.t("Wallpapers")
            subtitle: Tr.t("Change it")
            onClicked: Panels.wallpaperOpen = true
        }
    }
    Component {
        id: tile_lock
        QuickTile {
            icon: "lock"
            title: Tr.t("Lock")
            subtitle: Tr.t("Lock the screen")
            onClicked: { Panels.controlOpen = false; Quickshell.execDetached(["loginctl", "lock-session"]); }
        }
    }
}
