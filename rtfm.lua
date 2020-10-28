--[[
Read The Fucking Move - rtfm

-Register mob abilities as they happen
-Display mob abilities in text box
-Indicate damage potential and critial status ailments
-Display other notes regarding mob ability



Copyright © 2020, Rialya
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of rtfm nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Rialya BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]--


_addon.name    = 'rtfm'
_addon.author  = 'rialya'
_addon.version = '0.1.1'
_addon.command = 'rtfm'
_addon.commands = {'help'}

res = require('resources')
texts = require('texts')
config = require('config')
chat = require('chat')
--require('sets')
--res = require('resources')
--chat = require('chat')


default_settings = {
  bg = {
    alpha = 25
  },
  padding = 3
}



--Startup
settings = config.load(default_settings)
mobmove_box = texts.new(settings)
str = 'Recent Mob Moves: \n ${current_string}'
mobmove_box:text(str)
mobmove_box:font("Arial Black")
mobmove_box:size(12)
mobmove_box:show()




windower.register_event('action', function(act)
	local lines = L{}
	local actor = windower.ffxi.get_mob_by_id(act.actor_id)
	local targets = act.targets
	local param = act.param
	local self = windower.ffxi.get_player()
	local primarytarget = windower.ffxi.get_mob_by_id(targets[1].id)
	if actor and (actor.is_npc or primarytarget.name == self.name) and actor.name ~= self.name then 
		if (act['category'] == 7) then
			mobmove_box.current_string = ' '..actor.name.. ' : ' ..res.monster_abilities[targets[1].actions[1].param].en..' '
			windower.add_to_chat(123, ' '..actor.name.. ' : ' ..res.monster_abilities[targets[1].actions[1].param].en..' ')
		end
	end
end)
