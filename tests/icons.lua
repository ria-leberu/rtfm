package.path = './?.lua;' .. package.path
local image_count, status_loads, file_loads, releases, fallback = 0, 0, 0, 0, nil
local function texture()
    return { pointer = 100 + status_loads + file_loads, Release = function() releases = releases + 1 end }
end
package.loaded.ffi = {
    new = function() return {} end,
    cast = function(kind, value) return kind == 'uint32_t' and value.pointer or value end,
    C = {
        S_OK = 0, D3DFMT_A8R8G8B8 = 1, D3DPOOL_MANAGED = 1, D3DX_DEFAULT = 1,
        D3DXCreateTextureFromFileInMemoryEx = function(_, bitmap, size, _, _, _, _, _, _, _, _, _, _, _, output)
            assert(bitmap == 'native status bitmap' and size == 42)
            output[0] = texture()
            return 0
        end,
        D3DXCreateTextureFromFileA = function(_, path, output)
            assert(path == 'mock/assets\\icons\\fire.png')
            file_loads = file_loads + 1
            output[0] = texture()
            return 0
        end,
    },
}
package.loaded.d3d8 = { get_device = function() return {} end }
package.loaded.imgui = {
    Image = function(pointer, size) assert(type(pointer) == 'number' and size[1] == 16); image_count = image_count + 1 end,
    Text = function(value) fallback = value end,
    IsItemHovered = function() return true end,
    SetTooltip = function(label) assert(type(label) == 'string') end,
}
addon = { path = 'mock/' }
AshitaCore = { GetResourceManager = function() return {
    GetStatusIconByIndex = function(_, id)
        status_loads = status_loads + 1
        if id == 4 then return { Bitmap = 'native status bitmap', ImageSize = 42 } end
    end,
} end }
local icons = require('lib.icons')
icons.draw('status', 4, 'Paralysis', 16)
icons.draw('status', 4, 'Paralysis', 16)
assert(status_loads == 1 and image_count == 2)
icons.draw('fire', nil, 'Fire damage', 16)
assert(file_loads == 1 and image_count == 3)
icons.draw('status', 999, 'Status 999', 16)
icons.draw('status', 999, 'Status 999', 16)
assert(status_loads == 2 and fallback == '[Status 999]')
icons.clear()
assert(releases == 2)
icons.clear()
assert(releases == 2)
print('RTFM native icon/cache checks passed.')
