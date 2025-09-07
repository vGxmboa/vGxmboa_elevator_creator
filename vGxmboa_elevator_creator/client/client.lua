ESX = nil
local Elevators = {}
local PlayerData = {}

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end
    TriggerServerEvent("elevator:request")
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

RegisterNetEvent("elevator:update")
AddEventHandler("elevator:update", function(data)
    Elevators = data or {}
end)

RegisterNetEvent("elevator:created")
AddEventHandler("elevator:created", function(elevator)
    ESX.ShowNotification(_U('created_elevator', elevator.name))
    OpenElevatorManageMenu(elevator)
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local foundElevator = nil

        for _, elevator in pairs(Elevators) do
            for _, floor in pairs(elevator.floors) do
                local dist = #(playerCoords - vector3(floor.coords[1], floor.coords[2], floor.coords[3]))

                if dist < 20.0 then
                    local marker = elevator.marker or {type=1, scale={1.5,1.5,0.5}, color={0,150,255,150}}
                    DrawMarker(
                        marker.type,
                        floor.coords[1], floor.coords[2], floor.coords[3] - 1.0,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        marker.scale[1], marker.scale[2], marker.scale[3],
                        marker.color[1], marker.color[2], marker.color[3], marker.color[4],
                        false, true, 2, nil, nil, false
                    )
                end

                if dist < 2.0 then
                    foundElevator = elevator
                    break
                end
            end
            if foundElevator then break end
        end

        if foundElevator then
            sleep = 0
            ESX.ShowHelpNotification(_U('press_to_use'))
            if IsControlJustReleased(0, 38) then
                OpenElevatorMenu(foundElevator)
            end
        end

        Citizen.Wait(sleep)
    end
end)

function OpenElevatorMenu(elevator)
    local elements = {}
    for i, floor in ipairs(elevator.floors) do
        table.insert(elements, {
            label = floor.label,
            coords = floor.coords,
            heading = floor.heading
        })
    end

    if ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'elevator_menu') then
        ESX.UI.Menu.Close('default', GetCurrentResourceName(), 'elevator_menu')
    end

    ESX.UI.Menu.Open(
        'default', GetCurrentResourceName(), 'elevator_menu',
        {
            title    = elevator.name,
            align    = 'top-left',
            elements = elements
        },
        function(data, menu)
            local player = PlayerPedId()
            menu.close()

            DoScreenFadeOut(500)
            Citizen.Wait(600)

            local coords = data.current.coords
            SetEntityCoords(player, coords[1], coords[2], coords[3])

            if data.current.heading then
                SetEntityHeading(player, data.current.heading)
            end

            Citizen.Wait(600)
            DoScreenFadeIn(500)

            ESX.ShowNotification(_U('teleported_to', data.current.label))
        end,
        function(data, menu)
            menu.close()
        end
    )
end

RegisterCommand("elevatoradmin", function()
    ESX.TriggerServerCallback('elevator:canUseAdmin', function(canUse)
        if canUse then
            OpenElevatorAdminMenu()
        else
            ESX.ShowNotification(_U('no_permission'))
        end
    end)
end)

function OpenElevatorAdminMenu()
    local elements = {
        {label = "➕ " .. _U('enter_name'), value = "create"},
    }

    if Elevators and #Elevators > 0 then
        for _, elevator in ipairs(Elevators) do
            table.insert(elements, {label = "🏢 "..elevator.name, value = elevator})
        end
    end

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'elevator_admin', {
        title = _U('admin_menu_title'),
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        if data.current.value == "create" then
            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'elevator_name', {
                title = _U('enter_name')
            }, function(data2, menu2)
                local name = data2.value
                menu2.close()
                if name and name ~= "" then
                    TriggerServerEvent("elevator:create", name)
                end
            end, function(data2, menu2)
                menu2.close()
            end)

        elseif type(data.current.value) == "table" then
            OpenElevatorManageMenu(data.current.value)
        end
    end, function(data, menu)
        menu.close()
    end)
end

function OpenElevatorManageMenu(elevator)
    local elements = {
        {label = "➕ " .. _U('enter_label'), value = "add"},
        {label = "✏️ " .. _U('renamed_elevator', "..."), value = "rename"},
        {label = "❌ " .. _U('deleted_elevator', elevator.name), value = "delete"}
    }

    for i, floor in ipairs(elevator.floors) do
        table.insert(elements, {label = "📂 "..floor.label, value = {floor = floor, index = i}})
    end

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'elevator_manage', {
        title = _U('manage_menu_title', elevator.name),
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        if data.current.value == "add" then
            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'floor_label', {
                title = _U('enter_label')
            }, function(data2, menu2)
                local label = data2.value
                menu2.close()
                if label and label ~= "" then
                    local ped = PlayerPedId()
                    local coords = GetEntityCoords(ped)
                    local heading = GetEntityHeading(ped)
                    TriggerServerEvent("elevator:addFloor", elevator.name, label, coords, heading)
                    ESX.ShowNotification(_U('added_floor', label))
                end
            end, function(data2, menu2)
                menu2.close()
            end)

        elseif data.current.value == "rename" then
            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'rename_elevator', {
                title = _U('enter_name')
            }, function(data2, menu2)
                local newName = data2.value
                menu2.close()
                if newName and newName ~= "" then
                    TriggerServerEvent("elevator:rename", elevator.name, newName)
                    ESX.ShowNotification(_U('renamed_elevator', newName))
                end
            end, function(data2, menu2)
                menu2.close()
            end)

        elseif data.current.value == "delete" then
            TriggerServerEvent("elevator:delete", elevator.name)
            ESX.ShowNotification(_U('deleted_elevator', elevator.name))

        elseif type(data.current.value) == "table" then
            OpenFloorEditor(elevator, data.current.value.index, data.current.value.floor)
        end
    end, function(data, menu)
        menu.close()
    end)
end

function OpenFloorEditor(elevator, index, floor)
    local elements = {
        {label = "✏️ " .. _U('renamed_floor', "..."), value = "rename"},
        {label = "📍 " .. _U('updated_pos', floor.label), value = "setpos"},
        {label = "↩️ " .. _U('updated_heading', floor.label), value = "setheading"},
        {label = "❌ " .. _U('deleted_floor', floor.label), value = "delete"}
    }

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'floor_editor', {
        title = _U('floor_editor_title', floor.label),
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        if data.current.value == "rename" then
            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'rename_floor', {
                title = _U('enter_label')
            }, function(data2, menu2)
                local newLabel = data2.value
                menu2.close()
                if newLabel and newLabel ~= "" then
                    TriggerServerEvent("elevator:renameFloor", elevator.name, index, newLabel)
                    ESX.ShowNotification(_U('renamed_floor', newLabel))
                end
            end, function(data2, menu2)
                menu2.close()
            end)

        elseif data.current.value == "setpos" then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            TriggerServerEvent("elevator:updateFloorPos", elevator.name, index, coords)
            ESX.ShowNotification(_U('updated_pos', floor.label))

        elseif data.current.value == "setheading" then
            local ped = PlayerPedId()
            local heading = GetEntityHeading(ped)
            TriggerServerEvent("elevator:updateFloorHeading", elevator.name, index, heading)
            ESX.ShowNotification(_U('updated_heading', floor.label))

        elseif data.current.value == "delete" then
            TriggerServerEvent("elevator:deleteFloor", elevator.name, index)
            ESX.ShowNotification(_U('deleted_floor', floor.label))
        end
    end, function(data, menu)
        menu.close()
    end)
end
