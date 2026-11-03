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
local spell_scope = 'all'
local spell_target
local spell_target_query = { '' }
local spell_target_page = 1
local selected, cached_query, cached_scope, cached_moves
local targets = {}
local spell_tab = 'tracked'
local tracked_only = { false }

local function spell_rules(alerts, spell)
    local result, families = {}, {}
    for _, rule in ipairs(alerts:list()) do
        if (rule.kind == 'spell' or rule.scope == 'spell')
            and names.normalize(rule.move) == names.normalize(spell) then
            if rule.scope == 'family' then
                local key = names.normalize(rule.monster)
                local group = families[key]
                if not group then
                    group = { monster = rule.monster, move = rule.move, kind = 'spell',
                        scope = 'family', family_ids = {}, enabled = false }
                    families[key] = group
                    result[#result + 1] = group
                end
                group.family_ids[#group.family_ids + 1] = rule.family_id
                group.enabled = group.enabled or rule.enabled
            else
                result[#result + 1] = rule
            end
        end
    end
    return result
end

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
    scope, selected, query[1], cached_query = 'family', nil, '', nil
    is_open[1] = true
    cached_moves = nil
end

function window.open_search(text)
    window.open()
    query[1] = text or ''
end

function window.open_spells(target, target_scope)
    scope, selected, cached_query, cached_moves = 'spell', nil, nil, nil
    spell_tab, query[1], is_open[1] = tracked_only[1] and 'tracked' or 'untracked', '', true
    spell_target, spell_scope = target, target and (target_scope == 'family' and 'family' or 'notorious') or 'all'
    spell_target_query[1], spell_target_page = '', 1
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
    if clicked and not active then
        spell_tab, selected, page = value, nil, 1
        if value == 'untracked' then tracked_only[1] = false end
    end
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
        if scope == 'spell' and query[1] == '' then
            spell_filter_button('Tracked spells', 'tracked')
            imgui.SameLine()
            spell_filter_button('Untracked spells', 'untracked')
        end
        imgui.InputText('Search enemies, moves and spells', query, 128)
        if imgui.Checkbox('Tracked only', tracked_only) then
            page = 1
            if tracked_only[1] then spell_tab = 'tracked' end
        end
        if cached_query ~= query[1] or cached_scope ~= scope then page = 1 end
        if query[1]:match('%S') then
            if cached_query ~= query[1] or cached_scope ~= scope then targets = browser.search_all(query[1]) end
        elseif scope == 'spell' then
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
        local display_targets = targets
        if tracked_only[1] then
            local matches = browser.tracked_filter(alerts)
            display_targets = {}
            for _, target in ipairs(targets) do
                if matches(target, scope) then display_targets[#display_targets + 1] = target end
            end
            if selected and not matches(selected, scope) then selected, cached_moves = nil, nil end
        end
        page = math.min(page, math.max(1, math.ceil(#display_targets / page_size)))
        if imgui.BeginChild('##catalogue_targets', { 260, 360 }, 1, 0) then
            if #display_targets == 0 then imgui.Text('No matching entries.') end
            local pages = math.max(1, math.ceil(#display_targets / page_size))
            if imgui.Button('Previous##catalogue_page') and page > 1 then page = page - 1 end
            imgui.SameLine()
            if imgui.Button('Next##catalogue_page') and page < pages then page = page + 1 end
            imgui.Text(string.format('%d results - Page %d/%d', #display_targets, page, pages))
            for i = (page - 1) * page_size + 1, math.min(page * page_size, #display_targets) do
                local target = display_targets[i]
                if imgui.Selectable((target.result_label or target.name) .. '##target_' .. i,
                    selected == target) then
                    selected, cached_moves = target, nil
                end
            end
        end
        imgui.EndChild()
        imgui.SameLine()
        if imgui.BeginChild('##catalogue_moves', { 0, 360 }, 1, ImGuiWindowFlags_HorizontalScrollbar or 0x800) then
            local selected_scope = selected and (selected.catalogue_scope or scope) or scope
            if selected and selected_scope == 'spell' then
                imgui.Text(selected.name)
                imgui.Text('Track this spell for:')
                for _, option in ipairs({ { 'All enemies', 'all' }, { 'Specific NM', 'notorious' }, { 'Family', 'family' } }) do
                    if option[2] ~= 'all' then imgui.SameLine() end
                    local active = spell_scope == option[2]
                    if active then imgui.PushStyleColor(ImGuiCol_Button, appearance.button()) end
                    if imgui.Button(option[1]) then
                        spell_scope, spell_target, spell_target_page = option[2], nil, 1
                        spell_target_query[1] = ''
                    end
                    if active then imgui.PopStyleColor() end
                end
                local rule
                if spell_scope == 'all' then
                    rule = { monster = 'Any enemy', move = selected.name, scope = 'spell', kind = 'spell' }
                else
                    if imgui.InputText('Find NM / family', spell_target_query, 128) then spell_target_page = 1 end
                    local choices = browser.search(spell_scope, spell_target_query[1])
                    local pages = math.max(1, math.ceil(#choices / 10))
                    spell_target_page = math.min(spell_target_page, pages)
                    if imgui.BeginChild('##spell_scope_targets', { 0, 150 }, 1, 0) then
                        if #choices == 0 then imgui.Text('No matching entries.') end
                        for i = (spell_target_page - 1) * 10 + 1, math.min(spell_target_page * 10, #choices) do
                            local target = choices[i]
                            if imgui.Selectable(target.name .. '##spell_scope_' .. i,
                                spell_target and spell_target.name == target.name or false) then spell_target = target end
                        end
                    end
                    imgui.EndChild()
                    if imgui.Button('Previous##spell_scope') and spell_target_page > 1 then spell_target_page = spell_target_page - 1 end
                    imgui.SameLine()
                    if imgui.Button('Next##spell_scope') and spell_target_page < pages then spell_target_page = spell_target_page + 1 end
                    imgui.SameLine()
                    imgui.Text(string.format('%d/%d', spell_target_page, pages))
                    if spell_target then rule = browser.rule(spell_target, { name = selected.name, kind = 'spell' }, spell_scope) end
                end
                if rule then
                    imgui.Text('Scope: ' .. rule.monster)
                    if track_button(alerts, rule, 'spell_scope_track') then changed = true end
                else
                    imgui.Text('Select an NM or family above.')
                end
                imgui.Separator()
                imgui.Text('Saved casting rules')
                for i, rule in ipairs(spell_rules(alerts, selected.name)) do
                    local enabled = { rule.enabled }
                    if imgui.Checkbox('##spell_rule_' .. i, enabled) then
                        alerts:set(rule, enabled[1]); changed = true
                    end
                    imgui.SameLine()
                    imgui.Text(rule.scope == 'spell' and 'All enemies' or ((rule.scope == 'family' and 'Family: ' or 'Enemy: ') .. rule.monster))
                    imgui.SameLine()
                    if imgui.Button('Remove##spell_rule_' .. i) then
                        alerts:remove(rule); changed = true
                    end
                end
            elseif selected then
                imgui.Text(selected.name)
                if imgui.Button('Track spells') then show_spells = true end
                if selected_scope == 'family' then
                    imgui.Text(string.format('Applies to %d known catalogue names.', #selected.members))
                end
                if not cached_moves then
                    cached_moves = browser.moves_for(selected, selected.focus_move or '')
                end
                for i, rule in ipairs(selected.saved_rules or {}) do
                    if not tracked_only[1] or alerts:is_selected(rule) then
                        if track_button(alerts, rule, 'saved_group_' .. i) then changed = true end
                        imgui.SameLine()
                        imgui.Text(rule.move)
                    end
                end
                if #cached_moves == 0 and not selected.saved_rules then imgui.Text('No catalogued moves for this selection.') end
                for _, move in ipairs(cached_moves) do
                    local rule = browser.rule(selected, move, selected_scope)
                    local tracked = alerts:is_selected(rule)
                    if not tracked_only[1] or tracked then
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
                        if imgui.IsItemHovered() then
                            local details = move.varies and 'Effects vary between versions.'
                                or descriptions.tooltip({ monster = selected.name, move = move.name,
                                    action = 'uses', category = 11, action_id = move.id }, overrides)
                            if details ~= '' then imgui.SetTooltip(details) end
                        end
                        if tracked then imgui.PopStyleColor() end
                        if move.kind == 'spell' then
                            -- Spell icons/descriptions use a separate ID namespace.
                        elseif move.varies then
                            -- Version differences are explained on hover.
                        else
                            descriptions.draw({ monster = selected.name, move = move.name,
                                action = 'uses', category = 11, action_id = move.id }, overrides)
                        end
                        imgui.Separator()
                    end
                end
            else
                imgui.Text('Select a family, named NM, or spell.')
            end
        end
        imgui.EndChild()
        imgui.TextWrapped('Family lists and named NMs use upstream data plus reviewed additions. Spell alerts can target all enemies, one NM, or a family. Individual rules and engagement filters take priority.')
    end
    imgui.End()
    if show_spells then window.open_spells(selected, selected and (selected.catalogue_scope or scope)) end
    return changed
end

return window
