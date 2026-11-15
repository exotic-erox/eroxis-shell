local here = (package.searchpath("lib.palettes", package.path) or ""):match("^(.*)/lib/[^/]*$") or "."
local sources = { here .. "/../quickshell/eroxis/config/Palettes.js", here .. "/../../shell/config/Palettes.js" }

local palettes = {}
for _, path in ipairs(sources) do
    local file = io.open(path, "r")
    if file then
        local src = file:read("a")
        file:close()
        for flavor, body in src:gmatch("(%w+):%s*(%b{})") do
            local colours = {}
            for name, hex in body:gmatch('(%w+):%s*"#(%x%x%x%x%x%x)"') do colours[name] = hex end
            if colours.base then palettes[flavor] = colours end
        end
        break
    end
end

palettes.mocha = palettes.mocha or { base = "0a0a0a", surface0 = "1c1c1c", mauve = "ffffff" }
return palettes
