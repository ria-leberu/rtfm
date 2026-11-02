local imgui = require('imgui')
local browser = require('lib.catalogue_browser')
local descriptions = require('lib.descriptions')
local overrides = require('data.moves')
local spell_picker = require('lib.spell_picker')
local window = {}
local is_open = { false }
local scope = 'family'
local page, page_size = 1, 25
local query = { '' }
local spell_enemy = { '' }
local selected, cached_query, cached_scope, cached_moves
local targets = {}

local function tab(label, value)
    local active = scope == value
    if active then
        imgui.PushStyleColor(ImGuiCol_Button, { 0.1, 0.45, 0.1, 1 })
        imgui.PushStyleColor(ImGuiCol_ButtonHovered, { 0.15, 0.6, 0.15, 1 })
        imgui.PushStyleColor(ImGuiCol_ButtonActive, { 0.1, 0.35, 0.1, 1 })
    end
    local clicked = imgui.Button(label)
    if active then imgui.PopStyleColor(3) end
    if clicked and not active then
        scope, selected, cached_moves = value, nil, nil
        query[1] = ''
    end
end

local function track_button(alerts, rule, id)
    local tracked = alerts:is_selected(rule)
    if tracked then
        imgui.PushStyleColor(ImGuiCol_Button, { 0.1, 0.45, 0.1, 1 })
        imgui.PushStyleColor(ImGuiCol_ButtonHovered, { 0.15, 0.6, 0.15, 1 })
        imgui.PushStyleColor(ImGuiCol_ButtonActive, { 0.1, 0.35, 0.1, 1 })
    end
    local changed = imgui.Button((tracked and 'Untrack' or 'Track') .. '##' .. id)
    if changed then alerts:set(rule, not tracked) end
    if tracked then imgui.PopStyleColor(3) end
    return changed
end

function window.open()
    is_open[1] = true
    cached_moves = nil
end

function window.draw(alerts)
    if not is_open[1] then return spell_picker.draw(alerts) end
    local changed = false
    imgui.SetNextWindowSize({ 820, 520 }, ImGuiCond_FirstUseEver)
    if imgui.Begin('RTFM Move Catalogue', is_open, ImGuiWindowFlags_NoCollapse) then
        tab('Common families', 'family')
        imgui.SameLine()
        tab('Notorious monsters', 'notorious')
        imgui.SameLine()
        tab('Spells', 'spell')
        imgui.InputText('Search catalogue', query, 128)
        if cached_query ~= query[1] or cached_scope ~= scope then
            targets = browser.search(scope, query[1])
            cached_query, cached_scope = query[1], scope
            page = 1
        end
        if imgui.BeginChild('##catalogue_targets', { 260, 360 }, 1, 0) then
            if #targets == 0 then imgui.Text('No matching entries.') end
            local pages = math.max(1, math.ceil(#targets / page_size))
            if imgui.Button('Previous##catalogue_page') and page > 1 then page = page - 1 end
            imgui.SameLine()
            if imgui.Button('Next##catalogue_page') and page < pages then page = page + 1 end
            imgui.Text(string.format('Page %d/%d', page, pages))
            for i = (page - 1) * page_size + 1, math.min(page * page_size, #targets) do
                local target = targets[i]
                if imgui.Selectable(target.name .. '##target_' .. i, selected == target) then
                    selected, cached_moves = target, nil
                    if scope == 'notorious' then spell_enemy[1] = target.name end
                end
            end
        end
        imgui.EndChild()
        imgui.SameLine()
        if imgui.BeginChild('##catalogue_moves', { 0, 360 }, 1, ImGuiWindowFlags_HorizontalScrollbar or 0x800) then
            if selected and scope == 'spell' then
                imgui.Text(selected.name)
                imgui.Text('Any enemy casting this spell')
                if track_button(alerts, { monster = 'Any enemy', move = selected.name,
                    scope = 'spell', kind = 'spell' }, 'spell_any') then changed = true end
                imgui.Separator()
                imgui.InputText('Specific enemy', spell_enemy, 128)
                if spell_enemy[1]:match('%S') then
                    imgui.Text('Only this enemy casting this spell')
                    if track_button(alerts, { monster = spell_enemy[1], move = selected.name,
                        kind = 'spell' }, 'spell_enemy') then changed = true end
                end
            elseif selected then
                imgui.Text(selected.name)
                if imgui.Button('Track spells') then spell_picker.open(selected, scope) end
                if scope == 'family' then
                    imgui.Text(string.format('Applies to %d known catalogue names.', #selected.members))
                end
                if not cached_moves then
                    cached_moves = browser.moves_for(selected, '')
                end
                if #cached_moves == 0 then imgui.Text('No catalogued moves for this selection.') end
                for _, move in ipairs(cached_moves) do
                    local rule = browser.rule(selected, move, scope)
                    local tracked = alerts:is_selected(rule)
                    if tracked then
                        imgui.PushStyleColor(ImGuiCol_Button, { 0.1, 0.45, 0.1, 1 })
                        imgui.PushStyleColor(ImGuiCol_ButtonHovered, { 0.15, 0.6, 0.15, 1 })
                        imgui.PushStyleColor(ImGuiCol_ButtonActive, { 0.1, 0.35, 0.1, 1 })
                    end
                    local suffix = move.kind == 'spell' and 'catalogue_spell_' or 'catalogue_move_'
                    if imgui.Button((tracked and 'Untrack' or 'Track') .. '##' .. suffix .. move.id) then
                        alerts:set(rule, not tracked)
                        changed = true
                    end
                    if tracked then imgui.PopStyleColor(3) end
                    imgui.SameLine()
                    if tracked then imgui.PushStyleColor(ImGuiCol_Text, { 0.2, 1, 0.2, 1 }) end
                    imgui.Text((move.kind == 'spell' and 'Spell: ' or '') .. move.name)
                    if tracked then imgui.PopStyleColor() end
                    if move.kind == 'spell' then
                        -- Spell icons/descriptions use a separate ID namespace.
                    elseif move.varies then
                        imgui.SameLine()
                        imgui.Text('(varies by version)')
                    else
                        descriptions.draw({ monster = selected.name, move = move.name,
                            action = 'uses', category = 11, action_id = move.id }, overrides)
                    end
                    imgui.Separator()
                end
            else
                imgui.Text('Select a family, named NM, or spell.')
            end
        end
        imgui.EndChild()
        imgui.TextWrapped('Family lists and named NMs use upstream data plus reviewed additions. Spell alerts can target any enemy or one enemy. Individual rules and engagement filters take priority.')
    end
    imgui.End()
    if spell_picker.draw(alerts) then changed, cached_moves = true, nil end
    return changed
end

return window
