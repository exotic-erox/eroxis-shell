import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

SettingsPage {
    id: page
    pageId: "about"
    spacing: Theme.space10

    readonly property string repo: "https://github.com/exotic-erox/eroxis-shell"
    property var info: ({})       // set once: what this computer is
    property var live: ({})       // refreshed while the page is open: uptime, memory
    function value(k) { return info[k] ? info[k] : "\u2014"; }
    function bytes(n) { return SystemStats.formatBytes(Number(n) || 0, 1); }
    function screenList() {
        const out = [];
        for (let i = 0; i < Quickshell.screens.length; i++) {
            const s = Quickshell.screens[i];
            out.push(s.name + "  " + s.width + "\u00d7" + s.height);
        }
        return out.join("\n");
    }
    readonly property string screens: screenList()
    readonly property string memory: live.memTotal ? bytes(live.memUsed) + " of " + bytes(live.memTotal) : "\u2014"
    readonly property string disk: live.diskTotal ? bytes(live.diskUsed) + " of " + bytes(live.diskTotal) : "\u2014"
    readonly property string shellMemory: live.shellMem && Number(live.shellMem) > 0 ? bytes(live.shellMem) : "\u2014"

    // everything the bug-report button copies
    readonly property string report: [
        Distro.label,
        "System: " + Distro.host,
        "Kernel: " + value("kernel"),
        "Hyprland: " + value("hyprland"),
        "Quickshell: " + value("quickshell"),
        "Install: " + value("install"),
        "CPU: " + value("cpu") + (info.threads ? " (" + info.threads + " threads)" : ""),
        "GPU: " + value("gpu"),
        "Memory: " + memory,
        "Displays: " + screens.replace(/\n/g, ", "),
        "Theme: " + Config.theme.flavor
    ].join("\n")

    Process {
        running: true
        command: ["sh", "-c", [
            "echo \"kernel=$(uname -r)\"",
            "echo \"hostname=$(cat /etc/hostname 2>/dev/null || uname -n)\"",
            "echo \"cpu=$(sed -n 's/^model name[[:space:]]*: *//p' /proc/cpuinfo | head -n 1)\"",
            "echo \"threads=$(nproc 2>/dev/null)\"",
            "echo \"gpu=$(lspci 2>/dev/null | grep -iE 'vga|3d controller|display controller' | head -n 1 | sed 's/^[^:]*:[^:]*: //')\"",
            "echo \"hyprland=$(hyprctl version -j 2>/dev/null | sed -n 's/.*\"version\": *\"\\([^\"]*\\)\".*/\\1/p' | head -n 1)\"",
            "echo \"quickshell=$(qs --version 2>/dev/null | head -n 1 | sed 's/^quickshell *//; s/,.*//')\"",
            "if [ -e \"$HOME/.config/quickshell/eroxis/.eroxis-shell\" ]; then echo 'install=Permanent'; else echo 'install=Tapes, or run from the repository'; fi"
        ].join("\n")]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0) out[line.slice(0, i)] = line.slice(i + 1).trim();
                }
                page.info = out;
            }
        }
    }

    Process {
        id: sampler
        command: ["sh", "-c", [
            "echo \"uptime=$(uptime -p 2>/dev/null | sed 's/^up //')\"",
            "awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{print \"memTotal=\" t*1024; print \"memUsed=\" (t-a)*1024}' /proc/meminfo",
            "df -B1 --output=used,size / 2>/dev/null | tail -n 1 | awk '{print \"diskUsed=\" $1; print \"diskTotal=\" $2}'",
            "ps -eo rss=,args= | awk '/(qs|quickshell) .*-c eroxis/ && !/awk/ {s+=$1} END {print \"shellMem=\" s*1024}'"
        ].join("\n")]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0) out[line.slice(0, i)] = line.slice(i + 1).trim();
                }
                page.live = out;
            }
        }
    }
    Timer { interval: 4000; running: page.visible; repeat: true; triggeredOnStart: true; onTriggered: sampler.running = true }

    // ---- the top: the emblem, the name and version
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: Theme.space12
        Layout.bottomMargin: Theme.space8
        spacing: Theme.space6

        Logo {
            Layout.alignment: Qt.AlignHCenter
            size: 132
            animated: page.visible
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.space8
            Label { text: Distro.name; font.pixelSize: Theme.fontSize * 2; font.weight: Font.DemiBold }
            Label { text: "V." + Distro.version; color: Theme.accent; font.pixelSize: Theme.fontSize * 2; font.weight: Font.Light; Layout.alignment: Qt.AlignBottom }
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            color: Theme.subtext0
            text: Tr.t("A black-and-white desktop shell for Hyprland")
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Theme.space6
            spacing: Theme.space8
            ChipButton { text: Tr.t("Project page"); onClicked: Quickshell.execDetached(["xdg-open", page.repo]) }
            ChipButton { text: Tr.t("Report a problem"); onClicked: Quickshell.execDetached(["xdg-open", page.repo + "/issues/new/choose"]) }
            ChipButton { text: Tr.t("Copy system info"); onClicked: Quickshell.execDetached(["wl-copy", page.report]) }
        }
    }

    SettingsSection { text: Tr.t("This computer") }
    SettingsRow { title: Tr.t("System"); Label { color: Theme.subtext0; text: Distro.host } }
    SettingsRow { title: Tr.t("Kernel"); Label { mono: true; color: Theme.subtext0; text: page.value("kernel") } }
    SettingsRow { title: Tr.t("Uptime"); Label { color: Theme.subtext0; text: page.live.uptime ? page.live.uptime : "\u2014" } }
    SettingsRow { title: Tr.t("Processor"); Label { color: Theme.subtext0; elide: Text.ElideRight; Layout.maximumWidth: 360; text: page.value("cpu") + (page.info.threads ? "  \u00b7  " + page.info.threads : "") } }
    SettingsRow { title: Tr.t("Graphics"); Label { color: Theme.subtext0; elide: Text.ElideRight; Layout.maximumWidth: 360; text: page.value("gpu") } }
    SettingsRow { title: Tr.t("Memory"); Label { mono: true; color: Theme.subtext0; text: page.memory } }
    SettingsRow { title: Tr.t("Storage"); Label { mono: true; color: Theme.subtext0; text: page.disk } }
    SettingsRow { title: Tr.t("Displays"); Label { mono: true; color: Theme.subtext0; horizontalAlignment: Text.AlignRight; text: page.screens } }

    SettingsSection { text: Distro.name }
    SettingsRow { title: Tr.t("Version"); Label { mono: true; color: Theme.subtext0; text: Distro.version } }
    SettingsRow { title: Tr.t("Installed as"); Label { color: Theme.subtext0; text: page.value("install") } }
    SettingsRow { title: Tr.t("Memory used by Eroxis"); Label { mono: true; color: Theme.subtext0; text: page.shellMemory } }
    SettingsRow { title: Tr.t("Hyprland"); Label { mono: true; color: Theme.subtext0; text: page.value("hyprland") } }
    SettingsRow { title: Tr.t("Quickshell"); Label { mono: true; color: Theme.subtext0; text: page.value("quickshell") } }
    SettingsRow { title: Tr.t("Settings file"); Label { mono: true; color: Theme.subtext0; text: Config.path.replace(Quickshell.env("HOME"), "~") } }

    SettingsSection { text: Tr.t("About") }
    Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: Theme.subtext0
        text: Tr.t("Eroxis Shell is free software, released under the GNU General Public License, version 3 or later. It is built on the shell of Vyntaris. Thanks to everyone whose work it uses; see THIRD-PARTY.md.")
    }
    SettingsRow {
        title: Tr.t("Welcome screen")
        Button { text: Tr.t("Open"); onClicked: Panels.settings("welcome") }
    }
}
