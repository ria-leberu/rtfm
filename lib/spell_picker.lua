local imgui = require('imgui')
local appearance = require('lib.appearance')
local browser = require('lib.catalogue_browser')
local names = require('lib.names')
local picker = {}
local is_open = { false }
local enemy, query = { '' }, { '' }
local context_name, context_aliases, context_spells
local cached_query, spells, page = nil, {}, 1
local adding = false

function picker.open(target, scope)
    context_name, context_aliases = target.name, {}
    for _, alias in ipairs(target.aliases or {}) do context_aliases[#context_aliases + 1] = alias end
    context_spells = target.spells
    enemy[1] = scope == 'family' and '' or target.name
    query[1], cached_query, page, is_open[1] = '', nil, 1, true
    adding = false
end

function picker.draw(alerts)
    if not is_open[1] then return false end
    local changed = false
    imgui.SetNextWindowSize({ 480, 430 }, ImGuiCond_FirstUseEver)
    if imgui.Begin('RTFM Spell Tracking', is_open, ImGuiWindowFlags_NoCollapse) then
        imgui.InputText('Enemy name', enemy, 128)
        imgui.TextWrapped('Alerts when this specific enemy starts casting a selected spell.')
        if not enemy[1]:match('%S') then imgui.Text('Enter a specific enemy name, such as Moblin Topsman.') end
        if adding then
            if imgui.Button('Back to enemy spell list') then adding, cached_query, page = false, nil, 1 end
        elseif imgui.Button('Add another spell') then
            adding, cached_query, page, query[1] = true, nil, 1, ''
        end
        if adding then
            imgui.InputText('Search spells', query, 128)
            if cached_query ~= query[1] then
                spells, cached_query, page = browser.search('spell', query[1]), query[1], 1
            end
        else
            local target = { name = names.trim(enemy[1]) }
            if names.normalize(enemy[1]) == names.normalize(context_name) then
                target.aliases, target.spells = context_aliases, context_spells
            end
            spells = browser.spells_for(target, alerts)
            page = math.max(1, math.min(page, math.max(1, math.ceil(#spells / 25))))
        end
        local pages = math.max(1, math.ceil(#spells / 25))
        if imgui.Button('Previous##spell_picker') and page > 1 then page = page - 1 end
        imgui.SameLine()
        if imgui.Button('Next##spell_picker') and page < pages then page = page + 1 end
        imgui.SameLine()
        imgui.Text(string.format('Page %d/%d', page, pages))
        if imgui.BeginChild('##spell_picker_list', { 0, 270 }, 1, 0) then
            if #spells == 0 then
                imgui.Text(adding and 'No matching spells.' or 'No known spells. Use Add another spell to supply one.')
            end
            for i = (page - 1) * 25 + 1, math.min(page * 25, #spells) do
                local spell = spells[i]
                if enemy[1]:match('%S') then
                    local rule = { monster = names.trim(enemy[1]), move = spell.name, kind = 'spell' }
                    if names.normalize(enemy[1]) == names.normalize(context_name) then rule.aliases = context_aliases end
                    local tracked = alerts:is_selected(rule)
                    if tracked then
                        imgui.PushStyleColor(ImGuiCol_Button, appearance.button())
                        imgui.PushStyleColor(ImGuiCol_ButtonHovered, appearance.button('hover'))
                        imgui.PushStyleColor(ImGuiCol_ButtonActive, appearance.button('active'))
                    end
                    local label = adding and 'Add & track' or (tracked and 'Untrack' or 'Track')
                    if imgui.Button(label .. '##picker_spell_' .. spell.spell_id) then
                        alerts:set(rule, adding or not tracked)
                        changed = true
                    end
                    if tracked then imgui.PopStyleColor(3) end
                    imgui.SameLine()
                    if tracked then imgui.PushStyleColor(ImGuiCol_Text, appearance.palette().tracked) end
                    imgui.Text(spell.name)
                    if tracked then imgui.PopStyleColor() end
                else
                    imgui.Text(spell.name)
                end
            end
        end
        imgui.EndChild()
        if changed and adding then adding, cached_query, page = false, nil, 1 end
    end
    imgui.End()
    return changed
end

return picker
