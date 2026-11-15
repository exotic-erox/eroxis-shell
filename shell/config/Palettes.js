.pragma library

var palettes = {
    latte: {
        rosewater: "#1a1a1a",
        flamingo: "#262626",
        pink: "#333333",
        mauve: "#000000",
        red: "#404040",
        maroon: "#4d4d4d",
        peach: "#595959",
        yellow: "#666666",
        green: "#737373",
        teal: "#808080",
        sky: "#2e2e2e",
        sapphire: "#3a3a3a",
        blue: "#474747",
        lavender: "#202020",
        text: "#0a0a0a",
        subtext1: "#262626",
        subtext0: "#3d3d3d",
        overlay2: "#5c5c5c",
        overlay1: "#737373",
        overlay0: "#8a8a8a",
        surface2: "#bdbdbd",
        surface1: "#d4d4d4",
        surface0: "#e6e6e6",
        base: "#ffffff",
        mantle: "#f5f5f5",
        crust: "#ebebeb",
    },
    frappe: {
        rosewater: "#f2f2f2",
        flamingo: "#e6e6e6",
        pink: "#d9d9d9",
        mauve: "#ffffff",
        red: "#cccccc",
        maroon: "#bfbfbf",
        peach: "#b3b3b3",
        yellow: "#a6a6a6",
        green: "#999999",
        teal: "#8c8c8c",
        sky: "#cfcfcf",
        sapphire: "#c2c2c2",
        blue: "#b5b5b5",
        lavender: "#dedede",
        text: "#f0f0f0",
        subtext1: "#d6d6d6",
        subtext0: "#b8b8b8",
        overlay2: "#999999",
        overlay1: "#808080",
        overlay0: "#666666",
        surface2: "#4a4a4a",
        surface1: "#383838",
        surface0: "#2a2a2a",
        base: "#1a1a1a",
        mantle: "#141414",
        crust: "#0e0e0e",
    },
    macchiato: {
        rosewater: "#f2f2f2",
        flamingo: "#e6e6e6",
        pink: "#d9d9d9",
        mauve: "#ffffff",
        red: "#cccccc",
        maroon: "#bfbfbf",
        peach: "#b3b3b3",
        yellow: "#a6a6a6",
        green: "#999999",
        teal: "#8c8c8c",
        sky: "#cfcfcf",
        sapphire: "#c2c2c2",
        blue: "#b5b5b5",
        lavender: "#dedede",
        text: "#f2f2f2",
        subtext1: "#d9d9d9",
        subtext0: "#bababa",
        overlay2: "#9c9c9c",
        overlay1: "#828282",
        overlay0: "#686868",
        surface2: "#474747",
        surface1: "#333333",
        surface0: "#222222",
        base: "#111111",
        mantle: "#0b0b0b",
        crust: "#060606",
    },
    mocha: {
        rosewater: "#f2f2f2",
        flamingo: "#e6e6e6",
        pink: "#d9d9d9",
        mauve: "#ffffff",
        red: "#cccccc",
        maroon: "#bfbfbf",
        peach: "#b3b3b3",
        yellow: "#a6a6a6",
        green: "#999999",
        teal: "#8c8c8c",
        sky: "#cfcfcf",
        sapphire: "#c2c2c2",
        blue: "#b5b5b5",
        lavender: "#dedede",
        text: "#f5f5f5",
        subtext1: "#dcdcdc",
        subtext0: "#bdbdbd",
        overlay2: "#9e9e9e",
        overlay1: "#848484",
        overlay0: "#6a6a6a",
        surface2: "#454545",
        surface1: "#2e2e2e",
        surface0: "#1c1c1c",
        base: "#0a0a0a",
        mantle: "#050505",
        crust: "#000000",
    },
};

var accentNames = ["rosewater", "flamingo", "pink", "mauve", "red", "maroon", "peach",
                   "yellow", "green", "teal", "sky", "sapphire", "blue", "lavender"];
var accentChoices = ["mauve", "pink", "peach", "green"];

function isCustom(name) {
    return typeof name === "string" && /^#[0-9a-fA-F]{6}$/.test(name);
}

function hsl(hex) {
    var r = parseInt(hex.substr(1, 2), 16) / 255, g = parseInt(hex.substr(3, 2), 16) / 255,
        b = parseInt(hex.substr(5, 2), 16) / 255;
    var max = Math.max(r, g, b), min = Math.min(r, g, b), l = (max + min) / 2, d = max - min;
    var h = 0, s = 0;
    if (d > 0) {
        s = d / (1 - Math.abs(2 * l - 1));
        if (max === r) h = 60 * (((g - b) / d) % 6);
        else if (max === g) h = 60 * ((b - r) / d + 2);
        else h = 60 * ((r - g) / d + 4);
    }
    return { h: (h + 360) % 360, s: s, l: l };
}

function fromHsl(h, s, l) {
    h = ((h % 360) + 360) % 360;
    var c = (1 - Math.abs(2 * l - 1)) * s, x = c * (1 - Math.abs((h / 60) % 2 - 1)), m = l - c / 2;
    var rgb = h < 60 ? [c, x, 0] : h < 120 ? [x, c, 0] : h < 180 ? [0, c, x]
            : h < 240 ? [0, x, c] : h < 300 ? [x, 0, c] : [c, 0, x];
    return "#" + rgb.map(function (v) { return ("0" + Math.round((v + m) * 255).toString(16)).slice(-2); }).join("");
}

function isDark(pal) {
    return hsl(pal.base).l < 0.5;
}

function fit(color, dark) {
    var c = hsl(color);
    return dark ? fromHsl(c.h, Math.min(0.92, Math.max(0.6, c.s)), 0.77)
                : fromHsl(c.h, Math.min(0.92, Math.max(0.6, c.s)), 0.77);
}

function accent(pal, name) {
    return isCustom(name) ? fit(name, isDark(pal)) : (pal[name] || pal.blue);
}

function partnerOf(color) {
    var c = hsl(color);
    return fromHsl(c.h - 45, c.s, c.l);
}

function oklab(hex) {
    function lin(v) { return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }
    var r = lin(parseInt(hex.substr(1, 2), 16) / 255), g = lin(parseInt(hex.substr(3, 2), 16) / 255),
        b = lin(parseInt(hex.substr(5, 2), 16) / 255);
    var l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    var m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    var s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
    return [0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s];
}

function nearest(pal, color) {
    if (!isCustom(color)) return color in pal ? color : "blue";
    var t = oklab(color), best = "mauve", dist = Infinity;
    for (var i = 0; i < accentNames.length; i++) {
        var p = oklab(pal[accentNames[i]]);
        var d = 0.3 * Math.pow(p[0] - t[0], 2) + Math.pow(p[1] - t[1], 2) + Math.pow(p[2] - t[2], 2);
        if (d < dist) { dist = d; best = accentNames[i]; }
    }
    return best;
}

function luminance(hex) {
    function lin(v) { return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }
    return 0.2126 * lin(parseInt(hex.substr(1, 2), 16) / 255) + 0.7152 * lin(parseInt(hex.substr(3, 2), 16) / 255)
        + 0.0722 * lin(parseInt(hex.substr(5, 2), 16) / 255);
}

function contrast(a, b) {
    var la = luminance(a), lb = luminance(b);
    return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
}

function mix(a, b, t) {
    var out = "#";
    for (var i = 1; i < 7; i += 2) {
        var x = parseInt(a.substr(i, 2), 16), y = parseInt(b.substr(i, 2), 16);
        out += ("0" + Math.round(x + (y - x) * t).toString(16)).slice(-2);
    }
    return out;
}

// The colour moved towards another, only as far as it takes to read on this background.
function ensure(color, background, ratio, towards) {
    for (var t = 0; t <= 1; t += 0.02) {
        var c = mix(color, towards, t);
        if (contrast(c, background) >= ratio) return c;
    }
    return towards;
}

// A fill some text has to read on: darkened just enough where neither black nor white would.
// The same hue, only as dark as it takes to read on a light background.
function deepen(color, background, ratio) {
    var c = hsl(color);
    for (var l = c.l; l > 0; l -= 0.01) {
        var d = fromHsl(c.h, c.s, l);
        if (contrast(d, background) >= ratio) return d;
    }
    return "#000000";
}

function settled(fill) {
    if (contrast("#ffffff", fill) >= 4.5 || contrast("#11111b", fill) >= 4.5) return fill;
    return ensure(fill, "#ffffff", 4.5, "#000000");
}

function readableOn(fill, light, dark) {
    if (contrast(light, fill) >= 4.5) return light;
    return contrast("#ffffff", fill) >= contrast(dark, fill) ? "#ffffff" : dark;
}
