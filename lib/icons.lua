local imgui = require('imgui')
local icons = {}
local textures = {}
local backend
local status_variants = { [11] = 'bind', [28] = 'terror' }

local function get_texture(kind, id)
    local key = kind .. ':' .. tostring(id or '')
    if textures[key] ~= nil then return textures[key] or nil end
    local ok, texture = pcall(function()
        if not backend then backend = { ffi = require('ffi'), d3d8 = require('d3d8') } end
        local ffi, d3d8 = backend.ffi, backend.d3d8
        local output = ffi.new('IDirect3DTexture8*[1]')
        local result
        local variant = kind == 'status' and status_variants[id]
        if kind == 'status' and not variant then
            local resource = AshitaCore:GetResourceManager():GetStatusIconByIndex(id)
            if not resource or not resource.Bitmap or resource.ImageSize <= 0 then return end
            result = ffi.C.D3DXCreateTextureFromFileInMemoryEx(d3d8.get_device(), resource.Bitmap,
                resource.ImageSize, 0xFFFFFFFF, 0xFFFFFFFF, 1, 0, ffi.C.D3DFMT_A8R8G8B8,
                ffi.C.D3DPOOL_MANAGED, ffi.C.D3DX_DEFAULT, ffi.C.D3DX_DEFAULT, 0xFF000000,
                nil, nil, output)
        else
            local path = (addon.path or (AshitaCore:GetInstallPath() .. 'addons\\rtfm\\'))
                .. 'assets\\icons\\' .. (variant or kind) .. '.png'
            result = ffi.C.D3DXCreateTextureFromFileA(d3d8.get_device(), path, output)
        end
        if result == ffi.C.S_OK then return ffi.cast('IDirect3DTexture8*', output[0]) end
    end)
    textures[key] = ok and texture or false
    return textures[key] or nil
end

function icons.draw(kind, id, label, size, tooltip)
    local texture = get_texture(kind, id)
    if texture then
        imgui.Image(tonumber(backend.ffi.cast('uint32_t', texture)), { size, size })
    else
        imgui.Text('[' .. label .. ']')
    end
    if imgui.IsItemHovered() then imgui.SetTooltip(tooltip or label) end
end

function icons.clear()
    for _, texture in pairs(textures) do
        if texture then texture:Release() end
    end
    textures = {}
end

return icons
