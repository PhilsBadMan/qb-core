AddEventHandler('playerDropped', function(reason)
	local src = source
	if QBCore.Players[src] then
		local Player = QBCore.Players[src]
		TriggerEvent('qb-log:server:CreateLog', 'joinleave', 'Dropped', 'red', '**'.. GetPlayerName(src) .. '** ('..Player.PlayerData.license..') left..')
		Player.Functions.Save()
		QBCore.Players[src] = nil
	end
end)

CreateThread(function()
	local result = exports.oxmysql:fetchSync('SELECT * FROM permissions', {})
	if result[1] then
		for k, v in pairs(result) do
			QBCore.Config.Server.PermissionList[v.license] = {
				license = v.license,
				permission = v.permission,
				optin = true,
			}
		end
	end
end)

local function OnPlayerConnecting(name, setKickReason, deferrals)
    local player = source
    local license
    local identifiers = GetPlayerIdentifiers(player)
    deferrals.defer()

    -- mandatory wait!
    Wait(0)

    deferrals.update(string.format('Hello %s. Validating Your Rockstar License', name))

    for _, v in pairs(identifiers) do
        if string.find(v, 'license') then
            license = v
            break
        end
    end

    -- mandatory wait!
    Wait(2500)

    deferrals.update(string.format('Hello %s. We are checking if you are banned.', name))

    local isBanned, Reason = QBCore.Functions.IsPlayerBanned(player)
    local isLicenseAlreadyInUse = QBCore.Functions.IsLicenseInUse(license)

    Wait(2500)

    deferrals.update(string.format('Welcome %s to {Server Name}.', name))

    if not license then
        deferrals.done('No Valid Rockstar License Found')
    elseif isBanned then
	    deferrals.done(Reason)
    elseif isLicenseAlreadyInUse then
        deferrals.done('Duplicate Rockstar License Found')
    else
        deferrals.done()
        Wait(1000)
        TriggerEvent('connectqueue:playerConnect', name, setKickReason, deferrals)
    end
    --Add any additional defferals you may need!
end

AddEventHandler('playerConnecting', OnPlayerConnecting)

RegisterNetEvent('QBCore:server:CloseServer', function(reason)
	local src = source
    if QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god') then
        local reason = reason or 'No reason specified'
        QBCore.Config.Server.closed = true
        QBCore.Config.Server.closedReason = reason
        TriggerClientEvent('qbadmin:client:SetServerStatus', -1, true)
	else
		QBCore.Functions.Kick(src, 'You don\'t have permissions for this..', nil, nil)
    end
end)

RegisterNetEvent('QBCore:server:OpenServer', function()
	local src = source
    if QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god') then
        QBCore.Config.Server.closed = false
        TriggerClientEvent('qbadmin:client:SetServerStatus', -1, false)
    else
        QBCore.Functions.Kick(src, 'You don\'t have permissions for this..', nil, nil)
    end
  end
)

RegisterNetEvent('QBCore:UpdatePlayer', function(data)
	local src = source
	local ped = GetPlayerPed(src)
	local Player = QBCore.Functions.GetPlayer(src)
	if Player then
		Player.PlayerData.position = GetEntityCoords(ped)
		local newHunger = Player.PlayerData.metadata['hunger'] - QBCore.Config.Player.HungerRate
		local newThirst = Player.PlayerData.metadata['thirst'] - QBCore.Config.Player.ThirstRate
		if newHunger <= 0 then newHunger = 0 end
		if newThirst <= 0 then newThirst = 0 end
		Player.Functions.SetMetaData('thirst', newThirst)
		Player.Functions.SetMetaData('hunger', newHunger)
		TriggerClientEvent('hud:client:UpdateNeeds', src, newHunger, newThirst)
		Player.Functions.Save()
	end
end)

RegisterNetEvent('QBCore:Server:TriggerCallback', function(name, ...)
	local src = source
	QBCore.Functions.TriggerCallback(name, src, function(...)
		TriggerClientEvent('QBCore:Client:TriggerCallback', src, name, ...)
	end, ...)
end)

RegisterNetEvent('QBCore:Server:UseItem', function(item)
	local src = source
	if item and item.amount > 0 then
		if QBCore.Functions.CanUseItem(item.name) then
			QBCore.Functions.UseItem(src, item)
		end
	end
end)

RegisterNetEvent('QBCore:Server:RemoveItem', function(itemName, amount, slot)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	Player.Functions.RemoveItem(itemName, amount, slot)
end)

RegisterNetEvent('QBCore:Server:AddItem', function(itemName, amount, slot, info)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	Player.Functions.AddItem(itemName, amount, slot, info)
end)

RegisterNetEvent('QBCore:Server:SetMetaData', function(meta, data)
    local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if meta == 'hunger' or meta == 'thirst' then
		if data > 100 then
			data = 100
		end
	end
	if Player then
		Player.Functions.SetMetaData(meta, data)
	end
	TriggerClientEvent('hud:client:UpdateNeeds', src, Player.PlayerData.metadata['hunger'], Player.PlayerData.metadata['thirst'])
end)

AddEventHandler('chatMessage', function(source, n, message)
	local src = source
	if string.sub(message, 1, 1) == '/' then
		local args = QBCore.Shared.SplitStr(message, ' ')
		local command = string.gsub(args[1]:lower(), '/', '')
		CancelEvent()
		if QBCore.Commands.List[command] then
			local Player = QBCore.Functions.GetPlayer(tonumber(src))
			if Player then
				table.remove(args, 1)
				if (QBCore.Functions.HasPermission(src, 'god') or QBCore.Functions.HasPermission(src, QBCore.Commands.List[command].permission)) then
					if (QBCore.Commands.List[command].argsrequired and #QBCore.Commands.List[command].arguments ~= 0 and args[#QBCore.Commands.List[command].arguments] == nil) then
					    TriggerClientEvent('QBCore:Notify', src, 'All arguments must be filled out!', 'error')
					else
						QBCore.Commands.List[command].callback(src, args)
					end
				else
					TriggerClientEvent('QBCore:Notify', src, 'No Access To This Command', 'error')
				end
			end
		end
	end
end)

RegisterNetEvent('QBCore:CallCommand', function(command, args)
	local src = source
	if QBCore.Commands.List[command] then
		local Player = QBCore.Functions.GetPlayer(tonumber(src))
		if Player then
			if (QBCore.Functions.HasPermission(src, 'god')) or (QBCore.Functions.HasPermission(src, QBCore.Commands.List[command].permission)) or (QBCore.Commands.List[command].permission == Player.PlayerData.job.name) then
				if (QBCore.Commands.List[command].argsrequired and #QBCore.Commands.List[command].arguments ~= 0 and args[#QBCore.Commands.List[command].arguments] == nil) then
					TriggerClientEvent('QBCore:Notify', src, 'All arguments must be filled out!', 'error')
				else
					QBCore.Commands.List[command].callback(src, args)
				end
			else
				TriggerClientEvent('QBCore:Notify', src, 'No Access To This Command', 'error')
			end
		end
	end
end)

RegisterNetEvent('QBCore:AddCommand', function(name, help, arguments, argsrequired, callback, persmission)
	QBCore.Commands.Add(name, help, arguments, argsrequired, callback, persmission)
end)

RegisterNetEvent('QBCore:ToggleDuty', function()
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if Player.PlayerData.job.onduty then
		Player.Functions.SetJobDuty(false)
		TriggerClientEvent('QBCore:Notify', src, 'You are now off duty!')
	else
		Player.Functions.SetJobDuty(true)
		TriggerClientEvent('QBCore:Notify', src, 'You are now on duty!')
	end
	TriggerClientEvent('QBCore:Client:SetDuty', src, Player.PlayerData.job.onduty)
end)

RegisterNetEvent('QBCore:Command:CheckOwnedVehicle', function(VehiclePlate)
	if VehiclePlate then
		local result = exports.oxmysql:singleSync('SELECT * FROM player_vehicles WHERE plate = ?', { VehiclePlate })
		if result[1] then
			exports.oxmysql:execute('UPDATE player_vehicles SET state = ? WHERE citizenid = ?', { 1, result[1].citizenid })
			TriggerEvent('qb-garages:server:RemoveVehicle', result[1].citizenid, VehiclePlate)
		end
	end
end)

QBCore.Functions.CreateCallback('QBCore:HasItem', function(source, cb, items, amount)
	local src = source
	local retval = false
	local Player = QBCore.Functions.GetPlayer(src)
	if Player then
		if type(items) == 'table' then
			local count = 0
            		local finalcount = 0
			for k, v in pairs(items) do
				if type(k) == 'string'  then
					endthennfinalcount = 0
					for i, _ in pairs(items) do
						if i then finalcount = finalcount + 1 end
					end
					local item = Player.Functions.GetItemByName(k)
					if item then
						if item.amount >= v then
							count = count + 1
							if count == finalcount then
								retval = true
							end
						end
					end
				else
                    finalcount = #items
					local item = Player.Functions.GetItemByName(v)
					if item then
						if amount then
							if item.amount >= amount then
								count = count + 1
								if count == finalcount then
									retval = true
								end
							end
						else
							count = count + 1
							if count == finalcount then
								retval = true
							end
						end
					end
				end
			end
		else
			local item = Player.Functions.GetItemByName(items)
			if item then
				if amount then
					if item.amount >= amount then
						retval = true
					end
				else
					retval = true
				end
			end
		end
	end

	cb(retval)
end)
