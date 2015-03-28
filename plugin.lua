local plugin = RegisterPlugin('RTV', '1.0', 10) -- by EpicLoyd

local maplist = {}
local current = nil
local inprocess = false
local enabled = CreateCvar('japp_rtv_enabled', '0', CvarFlags.ARCHIVE)
local interval = CreateCvar('japp_rtv_time', '30000', CvarFlags.ARCHIVE)
local function Init()
 maplist = GetFileList('maps/mp/', '.bsp')
end

function RandMap()
	for i = 1, 6 do
		local n = math.random(1, #maplist)
		current['maps'][i] = {}
		current['maps'][i]['map'] = string.sub(maplist[n], 1, #maplist[n]-4)
		current['maps'][i]['voted'] = 0
	end
end


local function rtv(ply, args)
 if enabled:GetInteger() == 1 then
	if inprocess == true then
		SendReliableCommand(ply.id,'chat "^1RTV: ^2Already in progress\n"')
	else
		current = {} -- Clear last session
		current['maps'] = {}
		RandMap() -- get maps
		for i=0, #GetPlayers() do
		    SendReliableCommand(i,'chat "^1RockTheVote called by ^7' .. ply.name .. ' \n')
			SendReliableCommand(i,'chat "^1RTV: ^2Select map with !number of map (!1 !2)\n')
			for k,v in pairs(current['maps']) do
				SendReliableCommand(i,string.format('chat "%i: %s\n"',k,v['map']))
			end
		end
		current['end'] = GetTime() + interval:GetInteger()
		inprocess = true
	end
 else
	SendReliableCommand(ply.id,'print "^2RTV: ^1Disabled\n"')
 end
end

local function SumVotes()
local res = 0
	for i = 1,6 do
		res = res + current['maps'][i]['voted']
	end
	return res
end


local function Check()
	if current == nil then return end
	if GetTime() >= current['end'] or SumVotes() == #GetPlayers() then
	local d = 0
		local res = math.max(current['maps'][1]['voted'],
				             current['maps'][2]['voted'],
				             current['maps'][3]['voted'],
				             current['maps'][4]['voted'],
				             current['maps'][5]['voted'],
				             current['maps'][6]['voted'])
		if res == 0 then
				for k,v in pairs(GetPlayers()) do
					SendReliableCommand(v.id, string.format('chat "^1RTV: No maps voted :(\n"'))
					current = nil
					return
				end
		end
		for i = 1, 6 do 
			if current['maps'][i]['voted'] == res then
				for k,v in pairs(GetPlayers()) do
					SendReliableCommand(v.id, string.format('chat "^1RTV: Next map: %s (%i votes)\n"', current['maps'][i]['map'], current['maps'][i]['voted']))
				end
				SendConsoleCommand(2,string.format('map mp/%s',current['maps'][i]['map']))
			end
		end
		current = nil
	end
end

local function Vote(ply,msg,typ)
    if type(msg) == 'string' then ----CHATMSGRECV
		local tempstring = string.gsub(msg, ' ', '') --- Check for !rtv in chat
		if string.len(tempstring) == 4 and string.find(tempstring, '!rtv') then
			rtv(ply, nil)
		elseif string.len(tempstring) == 12 and string.find(tempstring, '!rockthevote') then
			rtv(ply, nil)
		end
		local num = string.match(msg, '!(%d+)')
		num = tonumber(num)
		if num == nil or ( num < 1 or num > 6 ) then
			return msg
		end
		current['maps'][num]['voted'] = current['maps'][num]['voted'] + 1
		return nil
	elseif type(msg) == 'table' then -- CLIENTCOMMAND
		local num = string.match(msg[1], '!(%d+)')
		num = tonumber(num)
		if num == nil or num < 1 or num > 6  then
			return nil
		end
		current['maps'][num]['voted'] = current['maps'][num]['voted'] + 1
		return 1
	end
end

AddListener('JPLUA_EVENT_RUNFRAME', Check)
AddListener('JPLUA_EVENT_CHATMSGRECV', Vote)
AddListener('JPLUA_EVENT_CLIENTCOMMAND', Vote)
AddClientCommand('!rtv', rtv)
AddClientCommand('!rockthevote', rtv)

Init()