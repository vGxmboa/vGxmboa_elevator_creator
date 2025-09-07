ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local elevators = {}

local function loadElevators()
    local data = LoadResourceFile(GetCurrentResourceName(), "elevators.json")
    if data then
        elevators = json.decode(data)
    else
        elevators = {}
    end
end

local function saveElevators()
    SaveResourceFile(GetCurrentResourceName(), "elevators.json", json.encode(elevators, { indent = true }), -1)
end

ESX.RegisterServerCallback('elevator:canUseAdmin', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and Config.AdminGroups then
        for _, group in ipairs(Config.AdminGroups) do
            if xPlayer.getGroup() == group then
                cb(true)
                return
            end
        end
    end
    cb(false)
end)

RegisterNetEvent("elevator:create")
AddEventHandler("elevator:create", function(name)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local allowed = false
    for _, group in ipairs(Config.AdminGroups) do
        if xPlayer.getGroup() == group then
            allowed = true
            break
        end
    end
    if not allowed then
        TriggerClientEvent('esx:showNotification', src, "🚫 " .. _U('no_permission'))
        return
    end

    if not name or name == "" then return end
    local newElevator = { name = name, floors = {} }
    table.insert(elevators, newElevator)
    saveElevators()
    TriggerClientEvent("elevator:update", -1, elevators)
    TriggerClientEvent("elevator:created", src, newElevator)
end)

RegisterNetEvent("elevator:addFloor")
AddEventHandler("elevator:addFloor", function(name, label, coords, heading)
    for _, elevator in ipairs(elevators) do
        if elevator.name == name then
            table.insert(elevator.floors, {
                label = label,
                coords = {coords.x, coords.y, coords.z},
                heading = heading
            })
            saveElevators()
            TriggerClientEvent("elevator:update", -1, elevators)
            return
        end
    end
end)

RegisterNetEvent("elevator:delete")
AddEventHandler("elevator:delete", function(name)
    for i, elevator in ipairs(elevators) do
        if elevator.name == name then
            table.remove(elevators, i)
            saveElevators()
            TriggerClientEvent("elevator:update", -1, elevators)
            return
        end
    end
end)

RegisterNetEvent("elevator:deleteFloor")
AddEventHandler("elevator:deleteFloor", function(name, index)
    for _, elevator in ipairs(elevators) do
        if elevator.name == name then
            table.remove(elevator.floors, index)
            saveElevators()
            TriggerClientEvent("elevator:update", -1, elevators)
            return
        end
    end
end)

RegisterNetEvent("elevator:rename")
AddEventHandler("elevator:rename", function(oldName, newName)
    for _, elevator in ipairs(elevators) do
        if elevator.name == oldName then
            elevator.name = newName
            saveElevators()
            TriggerClientEvent("elevator:update", -1, elevators)
            return
        end
    end
end)

RegisterNetEvent("elevator:renameFloor")
AddEventHandler("elevator:renameFloor", function(name, index, newLabel)
    for _, elevator in ipairs(elevators) do
        if elevator.name == name and elevator.floors[index] then
            elevator.floors[index].label = newLabel
            saveElevators()
            TriggerClientEvent("elevator:update", -1, elevators)
            return
        end
    end
end)

RegisterNetEvent("elevator:updateFloorPos")
AddEventHandler("elevator:updateFloorPos", function(name, index, coords)
    for _, elevator in ipairs(elevators) do
        if elevator.name == name and elevator.floors[index] then
            elevator.floors[index].coords = {coords.x, coords.y, coords.z}
            saveElevators()
            TriggerClientEvent("elevator:update", -1, elevators)
            return
        end
    end
end)

RegisterNetEvent("elevator:updateFloorHeading")
AddEventHandler("elevator:updateFloorHeading", function(name, index, heading)
    for _, elevator in ipairs(elevators) do
        if elevator.name == name and elevator.floors[index] then
            elevator.floors[index].heading = heading
            saveElevators()
            TriggerClientEvent("elevator:update", -1, elevators)
            return
        end
    end
end)

AddEventHandler("onResourceStart", function(res)
    if res == GetCurrentResourceName() then
        loadElevators()
    end
end)

RegisterNetEvent("elevator:request")
AddEventHandler("elevator:request", function()
    TriggerClientEvent("elevator:update", source, elevators)
end)
