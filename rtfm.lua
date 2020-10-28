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

texts = require('texts')
config = require('config')
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
text_box = texts.new(settings)

windower.register_event('action', function(action)
	if (action['category'] == 7) then
  
	end