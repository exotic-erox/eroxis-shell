.pragma library
.import "LogoShape.js" as LogoShape
.import "../config/Palettes.js" as Palettes

var shape = LogoShape.shape;

function accent(palette, accentName) {
    return Palettes.accent(palette, accentName);
}

function partner(palette, accentName) {
    return mix(Palettes.accent(palette, accentName), "#000000", 0.18);
}

// Rotates the hue and adds saturation.
function turn(color, degrees, saturation) {
    var c = Palettes.hsl(color);
    return Palettes.fromHsl(c.h + degrees, Math.min(1, c.s + saturation), c.l);
}

function mix(a, b, t) {
    var out = "#";
    for (var i = 1; i < 7; i += 2) {
        var x = parseInt(a.substr(i, 2), 16), y = parseInt(b.substr(i, 2), 16);
        out += ("0" + Math.round(x + (y - x) * t).toString(16)).slice(-2);
    }
    return out;
}

// One filled path in a viewBox ("x y w h"), drawn px wide.
function art(viewBox, d, fill, px) {
    var v = viewBox.split(" ").map(Number);
    return '<svg xmlns="http://www.w3.org/2000/svg" width="' + px + '" height="' + Math.max(1, Math.round(px * v[3] / v[2]))
        + '" viewBox="' + viewBox + '"><path fill="' + fill + '" fill-rule="evenodd" d="' + d + '"/></svg>';
}

// The whole emblem in one colour, px wide.
function full(color, unused1, unused2, px) {
    return art(shape.viewBox.join(" "), shape.all, color, px);
}
