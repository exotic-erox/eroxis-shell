.pragma library

// What the custom control center can be made of. Anything else in a saved layout (an old name, a typo, a hand edit)
// is ignored instead of breaking the panel.
var sections = ["media", "tiles", "sliders", "stats", "calendar", "notifications", "clock", "greeting", "emblem"];
var defaultSections = ["media", "tiles", "sliders", "stats", "calendar", "notifications"];
var tiles = ["wifi", "bluetooth", "night", "awake", "mic", "vpn", "dnd", "airplane", "dark", "profile", "screenshot", "picker", "clipboard", "timer", "wallpaper", "lock"];
var defaultTiles = ["wifi", "bluetooth", "night", "awake", "mic", "vpn"];
var widths = [420, 480, 560, 640];

// A layout is saved as text ("media,tiles,clock"), like the settings that are lists elsewhere in the shell.
function join(list) {
    return list.join(",");
}

// The ids of `list` (text, or a list) that are known, once each, in order. Not usable at all: the default.
function clean(list, known, fallback) {
    if (typeof list === "string") list = list === "" ? [] : list.split(",");
    if (!list || typeof list.length !== "number") return fallback.slice();
    var out = [];
    for (var i = 0; i < list.length; i++) {
        var id = list[i];
        if (known.indexOf(id) >= 0 && out.indexOf(id) < 0) out.push(id);
    }
    return out;
}

// A new list with `id` moved up (step -1) or down (step 1); the same list if it cannot move.
function move(list, id, step) {
    var out = list.slice();
    var i = out.indexOf(id), j = i + step;
    if (i < 0 || j < 0 || j >= out.length) return out;
    out.splice(i, 1);
    out.splice(j, 0, id);
    return out;
}

// A new list with `id` shown (put last) or not shown.
function setShown(list, id, shown) {
    var out = list.filter(function (x) { return x !== id; });
    return shown ? out.concat([id]) : out;
}

function width(value) {
    return widths.indexOf(value) >= 0 ? value : 480;
}
