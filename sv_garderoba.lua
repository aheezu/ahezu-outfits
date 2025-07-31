local function generateShareCode()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    while true do
        local code = ''
        for i = 1, 10 do
            local randomIndex = math.random(1, #chars)
            code = code .. chars:sub(randomIndex, randomIndex)
        end
        local result = MySQL.scalar.await('SELECT COUNT(*) FROM player_outfits WHERE share_code = ?', { code })
        if result == 0 then
            return code
        end
    end
end

ESX.RegisterServerCallback('westside-core:garderoba:server:getOutfits', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then 
		cb({}) 
		return 
	end
    
    local outfits = MySQL.query.await('SELECT id, name, skin, share_code FROM player_outfits WHERE owner = ? ORDER BY name ASC', { xPlayer.identifier })

    if outfits then
        for i = 1, #outfits do
            outfits[i].skin = json.decode(outfits[i].skin)
        end
        cb(outfits)
    else
        cb({})
    end
end)

RegisterNetEvent('westside-core:garderoba:server:saveOutfit', function(skinData, outfitName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not skinData or not outfitName or outfitName == '' then 
		return 
	end

    local shareCode = generateShareCode()
    local skinJson = json.encode(skinData)

    local success, result = pcall(function()
        return MySQL.insert.await('INSERT INTO player_outfits (owner, name, skin, share_code) VALUES (?, ?, ?, ?)', {
            xPlayer.identifier,
            outfitName,
            skinJson,
            shareCode
        })
    end)

    if not success then
        return
    end
    
    if result and result > 0 then
        xPlayer.showNotification('Pomyślnie zapisano strój', 'info', 3000)
    end
end)


RegisterNetEvent('westside-core:garderoba:server:updateOutfitName', function(outfitId, newName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not outfitId or not newName or newName == '' then 
		return 
	end

    local result = MySQL.update.await('UPDATE player_outfits SET name = ? WHERE id = ? AND owner = ?', {
        newName,
        outfitId,
        xPlayer.identifier
    })

    if result and result > 0 then
        xPlayer.showNotification('Pomyślnie zaaktualizowano nazwę stroju na ' .. newName, 'info', 3000)
    end
end)

RegisterNetEvent('westside-core:garderoba:server:deleteOutfit', function(outfitId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not outfitId then 
		return 
	end

    local result = MySQL.update.await('DELETE FROM player_outfits WHERE id = ? AND owner = ?', {
        outfitId,
        xPlayer.identifier
    })

    if result and result > 0 then
		xPlayer.showNotification('Usunięto strój', 'info', 3000)
    end
end)

ESX.RegisterServerCallback('westside-core:garderoba:server:getOutfitByCode', function(source, cb, code)
	local xPlayer = ESX.GetPlayerFromId(source)
    if not code or code == '' then 
		cb(nil) 
		return 
	end

    local result = MySQL.single.await('SELECT skin FROM player_outfits WHERE share_code = ?', { code })

    if result and result.skin then
        cb(json.decode(result.skin))
    else
        xPlayer.showNotification('Wprowadzono niepoprawny kod', 'error', 3000)
        cb(nil)
    end
end)