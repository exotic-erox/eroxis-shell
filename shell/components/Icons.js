.pragma library
.import "MaterialIcons.js" as Material

var material = {
    "wifi": ["network_wifi_1_bar", "network_wifi_2_bar", "network_wifi_3_bar", "signal_wifi_4_bar"],
    "wifi-off": "wifi_off",
    "ethernet": "lan",
    "volume": ["volume_mute", "volume_down", "volume_up"],
    "volume-x": "volume_off",
    "mic": "mic",
    "mic-off": "mic_off",
    "sun": "light_mode",
    "moon": "dark_mode",
    "cloud": "cloud",
    "cloud-off": "cloud_off",
    "partly-cloudy": "partly_cloudy_day",
    "partly-cloudy-night": "partly_cloudy_night",
    "rain": "rainy",
    "snow": "weather_snowy",
    "storm": "thunderstorm",
    "fog": "foggy",
    "sunset": "wb_twilight",
    "power": "power_settings_new",
    "restart": "restart_alt",
    "logout": "logout",
    "lock": "lock",
    "vpn": "vpn_key",
    "hotspot": "wifi_tethering",
    "search": "search",
    "eye": "visibility",
    "eye-off": "visibility_off",
    "play": "play_arrow",
    "pause": "pause",
    "stop": "stop",
    "next": "skip_next",
    "previous": "skip_previous",
    "record": "radio_button_checked",
    "music": "music_note",
    "headphones": "headphones",
    "bolt": "bolt",
    "battery": ["battery_android_0", "battery_android_1", "battery_android_2", "battery_android_3", "battery_android_4",
                "battery_android_5", "battery_android_6", "battery_android_full"],
    "close": "close",
    "check": "check",
    "plus": "add",
    "edit": "edit",
    "font": "text_fields",
    "minus": "remove",
    "info": "info",
    "alert": "warning",
    "bell": "notifications",
    "bell-off": "notifications_off",
    "chevron-left": "chevron_left",
    "chevron-right": "chevron_right",
    "arrow-down": "arrow_downward",
    "arrow-up": "arrow_upward",
    "external": "open_in_new",
    "refresh": "refresh",
    "history": "history",
    "cpu": "memory",
    "memory": "memory_alt",
    "thermometer": "thermostat",
    "disk": "hard_drive",
    "health": "monitor_heart",
    "settings": "settings",
    "sliders": "tune",
    "control": "toggle_on",
    "bluetooth": "bluetooth",
    "airplane": "flight",
    "airplane-off": "airplanemode_inactive",
    "camera": "photo_camera",
    "camera-off": "no_photography",
    "touchpad": "touch_app",
    "touchpad-off": "do_not_touch",
    "keyboard": "keyboard",
    "monitor": "monitor",
    "printer": "print",
    "globe": "language",
    "earth": "public",
    "translate": "translate",
    "calendar": "calendar_month",
    "gamepad": "sports_esports",
    "timer": "timer",
    "users": "group",
    "clock": "schedule",
    "cup": "coffee",
    "coffee": "coffee",
    "coffee-moon": "bedtime",
    "package": "package_2",
    "package-update": "deployed_code_update",
    "pacman": "deployed_code_update",
    "download": "download",
    "copy": "content_copy",
    "folder": "folder",
    "trash": "delete",
    "clipboard": "content_paste",
    "smartphone": "mobile",
    "tablet": "tablet_android",
    "laptop": "computer",
    "phone-ring": "mobile_sound",
    "send": "mobile_share",
    "image": "image",
    "windows": "select_window",
    "terminal": "terminal",
    "palette": "palette",
    "bar": "toolbar",
    "apps": "grid_view",
    "rocket": "rocket_launch",
    "accessibility": "accessibility_new",
};

var icons = {
    "power-saver": [{ d: "M12 2a10 10 0 1 0 0 20a10 10 0 1 0 0-20ZM5.2 8.83L12.32 9.92A2.1 2.1 0 1 1 10.62 13.58Z", e: true }],
    "power-balanced": [{ d: "M12 2a10 10 0 1 0 0 20a10 10 0 1 0 0-20ZM12 4.5L14.02 11.41A2.1 2.1 0 1 1 9.98 11.41Z", e: true }],
    "power-performance": [{ d: "M12 2a10 10 0 1 0 0 20a10 10 0 1 0 0-20ZM18.8 8.83L13.38 13.58A2.1 2.1 0 1 1 11.68 9.92Z", e: true }],
    "eroxis": [
        { fill: true, e: true, d: "M9.15 18.76L8.22 19.13L6.98 19.54L5.5 19.97L4.89 20.09L5.22 20.07L6.18 19.89L6.98 19.66L8.07 19.26ZM0.3 18.86L0.38 19.13L0.63 19.46L1.03 19.69L1.36 19.79L2.14 19.89L2.6 19.89L3.48 19.82L4.11 19.71L5.82 19.31L7.74 18.68L9.55 17.95L12.05 16.76L10.34 17.52L8.82 18.1L7.11 18.66L5.97 18.93L4.89 19.11L4.01 19.16L3.28 19.11L2.82 19.01L2.42 18.86L2.02 18.55L1.84 18.3L1.76 18.1L1.74 17.47L1.92 16.92L2.22 16.36L2.87 15.53L3.81 14.62L4.87 13.79L4.26 14.17L3.15 14.95L2.29 15.66L1.59 16.34L0.91 17.17L0.58 17.7L0.33 18.38ZM18.08 14.39L17.5 14.45L16.31 14.47L8.29 14.47L8.27 14.45L8.42 14.29L9.66 13.31L10.03 13.16L14.32 13.11L16.29 11.67L10.16 11.72L9.78 11.85L9.55 11.97L7.51 13.54L5.87 14.92L5.09 15.66L4.51 16.26L14.72 16.26L15 16.16ZM18.18 8.97L10.03 9L9.68 9.05L9.38 9.15L9.05 9.33L5.62 11.92L3.88 13.29L2.62 14.34L3.53 13.69L4.82 12.88L5.92 12.28L6.63 11.95L6.63 12.15L6.2 13.54L9.18 11.02L9.63 10.74L10.01 10.66L15.43 10.66L16.08 10.61ZM21.08 7.99L20.95 8.42L21.05 9.05L21.03 9.68L20.92 10.16L20.57 11.04L20.22 11.62L19.54 12.45L18.76 13.18L17.92 13.82L19.13 13.06L20.04 12.38L20.8 11.67L21.38 10.92L21.55 10.59L21.76 9.98L21.81 9.58L21.78 9.25L21.68 8.87L21.53 8.55L21.33 8.24ZM19.61 6.45L19.13 6.18L18.83 6.08L18.05 5.95L16.76 5.97L15.4 6.2L14.07 6.58L12.78 7.06L10.89 7.97L10.08 8.42L11.39 7.76L12.76 7.18L13.76 6.83L15.1 6.48L15.81 6.35L16.69 6.28L17.34 6.28L17.95 6.33L18.61 6.45L18.88 6.55ZM20.52 3.86L20.42 5.14L20.29 6.05L20.14 6.45L19.94 6.66L19.61 6.78L18.98 6.88L17.5 7.01L17.07 7.01L19.29 7.16L19.69 7.24L19.99 7.39L20.19 7.64L20.32 8.14L20.47 10.36L20.5 9.68L20.65 8.17L20.75 7.71L20.9 7.46L21.2 7.26L21.61 7.16L23.24 6.98L23.67 6.98L21.81 6.86L21.23 6.76L21.03 6.66L20.85 6.48L20.67 5.95L20.52 4.31Z" },
    ],
};

function volumeLevel(v) {
    return v > 0.6 ? 2 : v > 0.25 ? 1 : 0;
}

function signal(s) {
    return s > 1 ? s / 100 : s;
}
function wifiLevel(s) {
    s = signal(s);
    return s > 0.75 ? 3 : s > 0.5 ? 2 : s > 0.2 ? 1 : 0;
}

var outlineOnly = { "battery_android_0": true };

// Wi-Fi strength as solid shapes only: the whole fan dim, and a slice of it from the tip in colour, up to where
// Material's 1, 2 and 3 bars end. Their own shapes draw the rest as a 1 px outline, which came out blurred.
var wifiReach = [242, 339, 444];
function wifiFan(color, dimColor, level, px) {
    var fan = Material.paths["signal_wifi_4_bar"];
    var body;
    if (level < 0 || level >= wifiReach.length) {
        body = '<g fill="' + color + '">' + fan + '</g>';
    } else {
        var r = wifiReach[level], cx = 480, cy = -145, d = r * Math.SQRT1_2;
        var slice = '<path d="M' + cx + ' ' + cy + 'L' + (cx - d) + ' ' + (cy - d) + 'A' + r + ' ' + r + ' 0 0 1 '
            + (cx + d) + ' ' + (cy - d) + 'Z"/>';
        body = '<g fill="' + dimColor + '">' + fan + '</g><g fill="' + color + '">' + slice + '</g>';
    }
    return "data:image/svg+xml;charset=utf-8," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="' + px
        + '" height="' + px + '" viewBox="0 -960 960 960">' + body + '</svg>');
}

function svg(name, color, dimColor, stroke, level, px, filled) {
    if (name === "wifi") return wifiFan(color, dimColor, level, px);
    var m = material[name];
    if (m) {
        var list = m.levels || m;
        var pick = typeof list === "string" ? list : list[level < 0 || level >= list.length ? list.length - 1 : level];
        var shape = function (n) {
            return (filled && !outlineOnly[n] && Material.paths[n + "-fill"]) || Material.paths[n] || Material.paths["close"];
        };
        var inner = m.base && level >= 0 && pick !== m.base
            ? '<g fill="' + dimColor + '">' + shape(m.base) + '</g>' + shape(pick)
            : shape(pick);
        return "data:image/svg+xml;charset=utf-8," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="' + px
            + '" height="' + px + '" viewBox="0 -960 960 960" fill="' + color + '">' + inner + '</svg>');
    }
    var parts = icons[name] || [];
    var body = parts.map(function (q) {
        return '<path d="' + q.d + '" fill="' + color + '"' + (q.e ? ' fill-rule="evenodd"' : '') + '/>';
    }).join("");
    return "data:image/svg+xml;charset=utf-8," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="' + px
        + '" height="' + px + '" viewBox="0 0 24 24">' + body + '</svg>');
}
