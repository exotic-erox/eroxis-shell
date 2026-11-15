//@ pragma ShellId eroxis
import Quickshell
import QtQuick
import qs.modules.bar
import qs.modules.ipc
import qs.modules.settings
import qs.modules.system
import qs.modules.theme
import qs.modules.wallpaper
import qs.components
import qs.services

ShellRoot {
    Component.onCompleted: Quickshell.watchFiles = !Quickshell.shellDir.startsWith("/etc/xdg/")

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Variants {
        model: Quickshell.screens
        LeavingScreen {}
    }
    Backdrop {}

    Lock {}


    Auth {}

    Ipc {}

    AppTheme {}

    DayNight {}

    Session {}

    Welcome {}
}
