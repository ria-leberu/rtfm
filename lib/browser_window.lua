local imgui = require('imgui')
local appearance = require('lib.appearance')
local browser = require('lib.catalogue_browser')
local descriptions = require('lib.descriptions')
local overrides = require('data.moves')
local names = require('lib.names')
local sound_window = require('lib.sound_window')
local icon_buttons = require('lib.icon_buttons')
local window = {}
local is_open = { false }
local scope = 'family'
local page, page_size = 1, 25
local query = { '' }
local spell_enemy = { '' }
local selected, cached_query, cached_scope, cached_moves
local targets = {}
local spell_tab = 'tracked'

local function tab(label, value)
    local active = scope == value
    if active then
        imgui.PushStyleColor(ImGuiCol_Button, appearance.button())
        imgui.PushStyleColor(ImGuiCol_ButtonHovered, appearance.button('hover'))
        imgui.PushStyleColor(ImGuiCol_ButtonActive, appearance.button('active'))
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
        imgui.PushStyleColor(ImGuiCol_Button, appearance.button())
        imgui.PushStyleColor(ImGuiCol_ButtonHovered, appearance.button('hover'))
        imgui.PushStyleColor(ImGuiCol_ButtonActive, appearance.button('active'))
    end
    local changed = icon_buttons.track(id, tracked)
    if changed then alerts:set(rule, not tracked) end
    if tracked then imgui.PopStyleColor(3) end
    imgui.SameLine(0, 2)
    if icon_buttons.sound('sound_' .. id) then sound_window.open(rule) end
    return changed
end

function window.open()
    is_open[1] = true
    cached_moves = nil
end

function window.open_spells()
    scope, selected, cached_query, cached_moves = 'spell', nil, nil, nil
    spell_tab, query[1], is_open[1] = 'tracked', '', true
end

function window.open_group(group)
    local target_scope = group.scope == 'family' and 'family' or 'notorious'
    local target
    for _, entry in ipairs(browser.search(group.scope == 'family' and 'family' or 'monster', group.name)) do
        if names.normalize(entry.name) == names.normalize(group.name) then target = entry; break end
    end
    local copy = {}
    for key, value in pairs(target or { name = group.name, moves = {}, members = {} }) do copy[key] = value end
    local known, seen = {}, {}
    for _, move in ipairs(browser.moves_for(copy, '')) do known[names.normalize(move.name)] = true end
    copy.saved_rules = {}
    for _, rule in ipairs(group.rules) do
        local key = names.normalize(rule.move)
        if not known[key] and not seen[key] then
            copy.saved_rules[#copy.saved_rules + 1] = rule
            seen[key] = true
        end
    end
    selected = copy
    scope, cached_query, cached_moves, query[1], is_open[1] = target_scope, nil, nil, '', true
end

local function spell_filter_button(label, value)
    local active = spell_tab == value
    if active then
        imgui.PushStyleColor(ImGuiCol_Button, appearance.button())
        imgui.PushStyleColor(ImGuiCol_ButtonHovered, appearance.button('hover'))
        imgui.PushStyleColor(ImGuiCol_ButtonActive, appearance.button('active'))
    end
    local clicked = imgui.Button(label)
    if active then imgui.PopStyleColor(3) end
    if clicked and not active then spell_tab, selected, page = value, nil, 1 end
end

function window.draw(alerts)
    if not is_open[1] then return false end
    local changed, show_spells = false, false
    imgui.SetNextWindowSize({ 820, 520 }, ImGuiCond_FirstUseEver)
    if imgui.Begin('RTFM Move Catalogue', is_open, ImGuiWindowFlags_NoCollapse) then
        tab('Common families', 'family')
        imgui.SameLine()
        tab('Notorious monsters', 'notorious')
        imgui.SameLine()
        tab('Spells', 'spell')
        if scope == 'spell' then
            spell_filter_button('Tracked spells', 'tracked')
            imgui.SameLine()
            spell_filter_button('Untracked spells', 'untracked')
        end
        imgui.InputText('Search catalogue', query, 128)
        if cached_query ~= query[1] or cached_scope ~= scope then page = 1 end
        if scope == 'spell' then
            local tracked, seen = {}, {}
            local candidates = browser.search('spell', query[1])
            for _, entry in ipairs(candidates) do seen[names.normalize(entry.name)] = true end
            for _, rule in ipairs(alerts:list()) do
                if rule.kind == 'spell' or rule.scope == 'spell' then
                    local key = names.normalize(rule.move)
                    if rule.enabled then tracked[key] = true end
                    if not seen[key] and rule.move:lower():find(query[1]:lower(), 1, true) then
                        candidates[#candidates + 1] = { name = rule.move, kind = 'spell' }
                        seen[key] = true
                    end
                end
            end
            targets = {}
            for _, target in ipairs(candidates) do
                if (tracked[names.normalize(target.name)] == true) == (spell_tab == 'tracked') then
                    targets[#targets + 1] = target
                end
            end
            table.sort(targets, function(a,b) return a.name:lower() < b.name:lower() end)
            page = math.min(page, math.max(1, math.ceil(#targets / page_size)))
        elseif cached_query ~= query[1] or cached_scope ~= scope then
            targets = browser.search(scope, query[1])
        end
        cached_query, cached_scope = query[1], scope
        if imgui.BeginChild('##catalogue_targets', { 260, 360 }, 1, 0) then
            if #targets == 0 then imgui.Text('No matching entries.') end
            local pages = math.max(1, math.ceil(#targets / page_size))
            if imgui.Button('Previous##catalogue_page') and page > 1 then page = page - 1 end
            imgui.SameLine()
            if imgui.Button('Next##catalogue_page') and page < pages then page = page + 1 end
            imgui.Text(string.format('Page %d/%d', page, pages))
            for i = (page - 1) * page_size + 1, math.min(page * page_size, #targets) do
                local target = targets[i]
                if imgui.Selectable(target.name .. '##target_' .. i,
                    selected and selected.name == target.name or false) then
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
                imgui.Separator()
                imgui.Text('Saved casting rules')
                for i, rule in ipairs(alerts:list()) do
                    if (rule.kind == 'spell' or rule.scope == 'spell')
                        and names.normalize(rule.move) == names.normalize(selected.name) then
                        local enabled = { rule.enabled }
                        if imgui.Checkbox('##spell_rule_' .. i, enabled) then
                            alerts:set(rule, enabled[1]); changed = true
                        end
                        imgui.SameLine()
                        imgui.Text(rule.scope == 'spell' and 'Any enemy' or rule.monster)
                        imgui.SameLine()
                        if imgui.Button('Remove##spell_rule_' .. i) then
                            alerts:remove(rule); changed = true
                        end
                    end
                end
            elseif selected then
                imgui.Text(selected.name)
                if imgui.Button('Track spells') then show_spells = true end
                if scope == 'family' then
                    imgui.Text(string.format('Applies to %d known catalogue names.', #selected.members))
                end
                if not cached_moves then
                    cached_moves = browser.moves_for(selected, '')
                end
                for i, rule in ipairs(selected.saved_rules or {}) do
                    if track_button(alerts, rule, 'saved_group_' .. i) then changed = true end
                    imgui.SameLine()
                    imgui.Text(rule.move)
                end
                if #cached_moves == 0 and not selected.saved_rules then imgui.Text('No catalogued moves for this selection.') end
                for _, move in ipairs(cached_moves) do
                    local rule = browser.rule(selected, move, scope)
                    local tracked = alerts:is_selected(rule)
                    if tracked then
                        imgui.PushStyleColor(ImGuiCol_Button, appearance.button())
                        imgui.PushStyleColor(ImGuiCol_ButtonHovered, appearance.button('hover'))
                        imgui.PushStyleColor(ImGuiCol_ButtonActive, appearance.button('active'))
                    end
                    local suffix = move.kind == 'spell' and 'catalogue_spell_' or 'catalogue_move_'
                    if icon_buttons.track(suffix .. move.id, tracked) then
                        alerts:set(rule, not tracked)
                        changed = true
                    end
                    if tracked then imgui.PopStyleColor(3) end
                    imgui.SameLine(0, 2)
                    if icon_buttons.sound('catalogue_sound_' .. move.id) then sound_window.open(rule) end
                    imgui.SameLine()
                    if tracked then imgui.PushStyleColor(ImGuiCol_Text, appearance.palette().tracked) end
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
    if show_spells then window.open_spells() end
    return changed
end

return window
