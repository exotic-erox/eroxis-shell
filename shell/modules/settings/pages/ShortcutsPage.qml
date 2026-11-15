import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

// Change what the keyboard shortcuts are. Hyprland's configuration lists its shortcuts in a cache file when it loads; what
// you change is saved in keybinds.json next to the shell's settings, and read by that configuration the next time it
// loads (this page reloads it for you). Shortcuts without a name and the mouse ones are not listed.
SettingsPage {
    id: page
    pageId: "shortcuts"

    readonly property string home: Quickshell.env("HOME")
    readonly property string listPath: (Quickshell.env("XDG_CACHE_HOME") || home + "/.cache") + "/eroxis/keybinds.json"
    readonly property string minePath: (Quickshell.env("XDG_CONFIG_HOME") || home + "/.config") + "/quickshell/keybinds.json"

    property var binds: []
    property var overrides: ({})
    property string query: ""
    property string editing: ""
    property var mods: ({ SUPER: true, CTRL: false, ALT: false, SHIFT: false })
    property string pressed: ""

    readonly property var shown: {
        const q = query.trim().toLowerCase();
        return q === "" ? binds : binds.filter(b => (b.description + " " + b.keys).toLowerCase().includes(q));
    }
    readonly property bool anyChanged: Object.keys(overrides).length > 0
    readonly property string combo: {
        if (pressed === "") return "";
        const order = ["SUPER", "CTRL", "ALT", "SHIFT"].filter(m => mods[m]);
        return order.concat([pressed]).join(" + ");
    }

    function norm(keys) {
        const parts = keys.toLowerCase().split("+").map(s => s.trim()).filter(s => s !== "");
        const key = parts.pop() ?? "";
        return parts.sort().concat([key]).join("+");
    }
    function usedBy(bind, keys) {
        if (keys === "") return null;
        const want = norm(keys);
        return binds.find(b => b.id !== bind.id && b.keys !== "" && norm(b.keys) === want) ?? null;
    }

    function save() {
        const text = JSON.stringify(overrides);
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1" && hyprctl reload',
            "sh", minePath, text]);
    }
    function set(bind, keys) {
        const next = Object.assign({}, overrides);
        if (keys === bind.default) delete next[bind.id]; else next[bind.id] = keys;
        overrides = next;
        editing = "";
        save();
    }
    function reset(id) {
        const next = Object.assign({}, overrides);
        delete next[id];
        overrides = next;
        editing = "";
        save();
    }
    function resetAll() { overrides = ({}); editing = ""; save(); }
    function edit(bind) {
        if (editing === bind.id) { editing = ""; return; }
        editing = bind.id;
        pressed = "";
        const parts = bind.keys.split("+").map(s => s.trim());
        mods = { SUPER: parts.includes("SUPER"), CTRL: parts.includes("CTRL"), ALT: parts.includes("ALT"), SHIFT: parts.includes("SHIFT") };
    }

    function keyName(k) {
        if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(k);
        if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(k);
        if (k >= Qt.Key_F1 && k <= Qt.Key_F24) return "F" + (k - Qt.Key_F1 + 1);
        const names = {};
        names[Qt.Key_Return] = "Return"; names[Qt.Key_Enter] = "Return"; names[Qt.Key_Space] = "Space";
        names[Qt.Key_Tab] = "Tab"; names[Qt.Key_Backtab] = "Tab"; names[Qt.Key_Delete] = "Delete";
        names[Qt.Key_Backspace] = "BackSpace"; names[Qt.Key_Escape] = "Escape"; names[Qt.Key_Insert] = "Insert";
        names[Qt.Key_Home] = "Home"; names[Qt.Key_End] = "End"; names[Qt.Key_PageUp] = "Prior"; names[Qt.Key_PageDown] = "Next";
        names[Qt.Key_Left] = "left"; names[Qt.Key_Right] = "right"; names[Qt.Key_Up] = "up"; names[Qt.Key_Down] = "down";
        names[Qt.Key_Print] = "Print"; names[Qt.Key_Period] = "period"; names[Qt.Key_Comma] = "comma";
        names[Qt.Key_Minus] = "minus"; names[Qt.Key_Equal] = "equal"; names[Qt.Key_Slash] = "slash";
        names[Qt.Key_Backslash] = "backslash"; names[Qt.Key_BracketLeft] = "bracketleft"; names[Qt.Key_BracketRight] = "bracketright";
        names[Qt.Key_Semicolon] = "semicolon"; names[Qt.Key_Apostrophe] = "apostrophe"; names[Qt.Key_QuoteLeft] = "grave";
        return names[k] ?? "";
    }

    FileView {
        path: page.listPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try { page.binds = JSON.parse(text()); } catch (e) { page.binds = []; }
        }
    }
    FileView {
        path: page.minePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try { page.overrides = JSON.parse(text()); } catch (e) { page.overrides = ({}); }
        }
    }

    Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: Theme.subtext0
        text: Tr.t("Choose Change, pick the modifier keys, then press the key. The change applies at once. Your own additions can still go in ~/.config/hypr/user.lua.")
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.space8
        SearchField {
            id: search
            Layout.fillWidth: true
            placeholder: Tr.t("Search shortcuts…")
            count: page.shown.length
            onTextChanged: page.query = text
        }
        ChipButton { visible: page.anyChanged; text: Tr.t("Reset all"); onClicked: page.resetAll() }
    }

    Label {
        visible: page.binds.length === 0
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: Theme.subtext0
        text: Tr.t("The list appears once Hyprland has loaded Eroxis Shell's configuration.")
    }
    ChipButton {
        visible: page.binds.length === 0
        text: Tr.t("Load it now")
        onClicked: Quickshell.execDetached(["hyprctl", "reload"])
    }

    Repeater {
        model: page.shown

        delegate: ColumnLayout {
            id: row
            required property var modelData
            readonly property bool open: page.editing === modelData.id
            readonly property bool changed: page.overrides[modelData.id] !== undefined
            readonly property var clash: page.usedBy(modelData, page.combo)
            Layout.fillWidth: true
            spacing: Theme.space6

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space8
                Label {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: row.modelData.description
                }
                Label {
                    color: row.changed ? Theme.accent : Theme.subtext0
                    text: row.modelData.keys === "" ? Tr.t("Off") : row.modelData.keys
                }
                ChipButton { visible: row.changed && !row.open; text: Tr.t("Reset"); onClicked: page.reset(row.modelData.id) }
                ChipButton { on: row.open; text: row.open ? Tr.t("Cancel") : Tr.t("Change"); onClicked: page.edit(row.modelData) }
            }

            Rectangle {
                visible: row.open
                Layout.fillWidth: true
                implicitHeight: editor.implicitHeight + 2 * Theme.space10
                radius: Theme.r(10)
                color: Theme.mantle

                ColumnLayout {
                    id: editor
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space10 }
                    spacing: Theme.space8

                    RowLayout {
                        spacing: Theme.space6
                        Repeater {
                            model: ["SUPER", "CTRL", "ALT", "SHIFT"]
                            delegate: ChipButton {
                                required property string modelData
                                text: modelData
                                on: page.mods[modelData]
                                onClicked: {
                                    const next = Object.assign({}, page.mods);
                                    next[modelData] = !next[modelData];
                                    page.mods = next;
                                    capture.forceActiveFocus();
                                }
                            }
                        }
                    }

                    FocusScope {
                        id: capture
                        Layout.fillWidth: true
                        implicitHeight: 34
                        focus: row.open
                        onVisibleChanged: if (visible) forceActiveFocus()
                        Keys.onPressed: event => {
                            const name = page.keyName(event.key);
                            if (name === "") return;
                            page.pressed = name;
                            event.accepted = true;
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.r(8)
                            color: Theme.base
                            border { width: capture.activeFocus ? 2 : 1; color: capture.activeFocus ? Theme.accent : Theme.controlEdge }
                            Label {
                                anchors.centerIn: parent
                                color: page.combo === "" ? Theme.subtext0 : Theme.text
                                text: page.combo === "" ? Tr.t("Press the key…") : page.combo
                            }
                            MouseArea { anchors.fill: parent; onClicked: capture.forceActiveFocus() }
                        }
                    }

                    Label {
                        visible: row.clash !== null && page.combo !== ""
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: Theme.warning
                        text: row.clash ? Tr.f("Also used by “{0}”. Both will run.", row.clash.description) : ""
                    }

                    RowLayout {
                        spacing: Theme.space6
                        ChipButton { text: Tr.t("Save"); on: page.combo !== ""; onClicked: if (page.combo !== "") page.set(row.modelData, page.combo) }
                        ChipButton { text: Tr.t("Turn off"); onClicked: page.set(row.modelData, "") }
                        ChipButton { visible: row.changed; text: Tr.t("Back to") + " " + row.modelData.default; onClicked: page.reset(row.modelData.id) }
                    }
                }
            }
        }
    }
}
