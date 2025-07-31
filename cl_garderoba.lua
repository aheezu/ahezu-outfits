exports('openWardrobe', function()
    ESX.TriggerServerCallback('westside-core:garderoba:server:getOutfits', function(outfits)
        if not outfits then outfits = {} end
        local options = {}

        table.insert(options, {
            title = 'Zapisz obecny strój',
            icon = 'fa-solid fa-floppy-disk',
            onSelect = function()
                SaveOutfitMenu()
            end
        })

        table.insert(options, {
            title = 'Użyj kodu stroju',
            icon = 'fa-solid fa-key',
            onSelect = function()
                UseSharedCode()
            end
        })

        table.insert(options, {
            title = 'Twoje stroje',
            icon = 'fa-solid fa-person-shelter',
            disabled = #outfits == 0,
            description = #outfits > 0 and ('Posiadasz ' .. #outfits .. 'zapisanych strojów') or 'Nie masz jeszcze żadnych strojów',
            onSelect = function()
                OpenSubMenu(outfits)
            end
        })

        lib.registerContext({
            id = 'wardrobe_main',
            title = 'Garderoba',
            options = options
        })
        lib.showContext('wardrobe_main')
    end)
end)

function OpenSubMenu(outfits)
    local options = {}

    for _, outfit in ipairs(outfits) do
        table.insert(options, {
            title = outfit.name,
            description = 'Kod: ' .. outfit.share_code,
            icon = 'fa-solid fa-shirt',
            onSelect = function()
                OpenFitsMenu(outfit)
            end
        })
    end

    lib.registerContext({
        id = 'wardrobe_my_outfits',
        title = 'Twoje stroje',
        options = options,
        menu = 'wardrobe_main'
    })
    lib.showContext('wardrobe_my_outfits')
end

function OpenFitsMenu(outfit)
    lib.registerContext({
        id = 'outfit_actions',
        title = 'Strój: ' .. outfit.name,
        options = {
            {
                title = 'Załóż',
                icon = 'fa-solid fa-user-check',
				onSelect = function()
					TriggerEvent('skinchanger:loadClothes', outfit.skin)
					TriggerEvent('skinchanger:persistent', function(skin)
						TriggerServerEvent('esx_skin:save', skin)
						currentSkin = skin
						exports['westside-hud']:Notify('Strój został założony', 3000, 'success')						
					end)
				end
            },
            {
                title = 'Edytuj nazwę',
                icon = 'fa-solid fa-pen-to-square',
                onSelect = function()
                    local newName = lib.inputDialog('Edytuj nazwę', { { type = 'input', label = 'Wprowadź nową nazwę dla stroju', required = true }})
					if newName and newName[1] and newName[1] ~= '' then
						TriggerServerEvent('westside-core:garderoba:server:updateOutfitName', outfit.id, newName[1])
						Wait(500)
						openWardrobeMenu()
					elseif newName then
						exports['westside-hud']:Notify('Nazwa nie może być pusta', 3000, 'error')
					end
                end
            },
            {
                title = 'Kopiuj kod udostępniania',
                icon = 'fa-solid fa-copy',
                onSelect = function()
					lib.setClipboard(outfit.share_code)
                    exports['westside-hud']:Notify('Kod udostępniania ' .. outfit.share_code ..' został skopiowany do schowka', 3000, 'info')
                end
            },
            {
                title = 'Usuń strój',
                icon = 'fa-solid fa-trash-can',
                iconColor = '#C70039',
				onSelect = function()
				local confirmed = lib.alertDialog({
					header = 'Potwierdzenie usunięcia',
					content = 'Czy na pewno chcesz usunąć ten strój Tej operacji nie można cofnąć',
					centered = true,
					cancel = true,
					labels = { confirm = 'Tak', cancel = 'Nie' }
				})
					if confirmed == 'confirm' then
						TriggerServerEvent('westside-core:garderoba:server:deleteOutfit', outfit.id)
						Wait(500)
						openWardrobeMenu()
					end
                end
            }
        },
        menu = 'wardrobe_my_outfits'
    })
    lib.showContext('outfit_actions')
end

function SaveOutfitMenu()
    local outfitName = lib.inputDialog('Zapisz strój', { { type = 'input', label = 'Wprowadź nazwę dla swojego stroju', required = true, min = 1, max = 50 }})
	if not outfitName or not outfitName[1] or outfitName[1] == '' then 
		if outfitName then exports['westside-hud']:Notify('Nazwa nie może być pusta', 3000, 'error') end
		return 
	end

	TriggerEvent('skinchanger:getSaveable', function(skin)
		print(json.encode(skin))
		TriggerServerEvent('westside-core:garderoba:server:saveOutfit', skin, outfitName[1])
		Wait(500)
		openWardrobeMenu()
	end)
end

function UseSharedCode()
   local code =  lib.inputDialog('Użyj kodu', {{ type = 'input', label = 'Wprowadź kod udostępniania stroju', required = true }})
	if not code or not code[1] or code[1] == '' then 
		return 
	end
        
	ESX.TriggerServerCallback('westside-core:garderoba:server:getOutfitByCode', function(skinData)
		if skinData then
			lib.registerContext({
				id = 'shared_outfit_actions',
				title = 'Strój z kodu',
				options = {
					{
						title = 'Załóż ten strój',
						icon = 'fa-solid fa-user-check',
						onSelect = function()
							TriggerEvent('skinchanger:loadClothes', skinData)
							Wait(300)
							TriggerEvent('skinchanger:getSkin', function(newSkin)
								TriggerServerEvent('esx_skin:save', newSkin)
								exports['westside-hud']:notify('Strój został założony', 3000, 'success')
							end)
						end
					},
					{
						title = 'Zapisz ten strój w swojej szafie',
						icon = 'fa-solid fa-download',
						onSelect = function()
							local newName =  lib.inputDialog('Zapisz strój', {{ type = 'input', label = 'Wprowadź nazwę dla swojego stroju', required = true }})
							if newName and newName[1] and newName[1] ~= '' then
								TriggerServerEvent('westside-core:garderoba:server:saveOutfit', skinData, newName[1])
								Wait(500)
								openWardrobeMenu()
							elseif newName then
								exports['westside-hud']:notify('Nazwa nie może być pusta', 3000, 'error')
							end
						end
					}
				}
			})
			lib.showContext('shared_outfit_actions')
		end
	end, code[1])
end