local QBCore = exports['qb-core']:GetCoreObject()

-- Variables (must be declared first)
local isInMenu = false
local activeTargets = {}
local pedToAirport = {} -- map ped -> airport index for safety

-- Utility Functions
local function randomId()
    return tostring(math.random(100000, 999999))
end

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(_x, _y)
end

-- Main Functions
local function OpenAirportMenu(airport)
    if isInMenu then
        return
    end
    isInMenu = true

    local opts = {}
    for i, dest in ipairs(airport.destinations) do
        opts[#opts + 1] = {
            title = dest.label,
            description = "Board the plane to " .. dest.label,
            event = 'zindro:travelOptionSelected',
            args = {
                destination = dest,
                departure = airport
            }
        }
    end

    local ctxId = 'zindro_travel_' .. randomId()

    lib.registerContext({
        id = ctxId,
        title = 'Fly To:',
        options = opts
    })

    lib.showContext(ctxId)

    -- safety: reset if stuck
    Citizen.SetTimeout(6000, function()
        if isInMenu then
            isInMenu = false
        end
    end)
end

local function StartTravelSequence(destination, departureAirport)
    local player = PlayerPedId()
    local planeModel = GetHashKey("nimbus")

    RequestModel(planeModel)
    while not HasModelLoaded(planeModel) do Wait(0) end

    local spawnPos = departureAirport.planeSpawn
    local airSpawn = vector3(spawnPos.x, spawnPos.y, spawnPos.z + 150.0)

    DoScreenFadeOut(1000)
    Wait(1500)

    local plane = CreateVehicle(planeModel, airSpawn.x, airSpawn.y, airSpawn.z, spawnPos.w, true, false)
    SetEntityHeading(plane, spawnPos.w)
    SetEntityVelocity(plane, 0.0, 60.0, 0.0)

    local pilotModel = GetHashKey("s_m_m_pilot_01")
    RequestModel(pilotModel)
    while not HasModelLoaded(pilotModel) do Wait(0) end

    local pilot = CreatePedInsideVehicle(plane, 1, pilotModel, -1, true, false)

    -- warp player into passenger seat (index 1)
    TaskWarpPedIntoVehicle(player, plane, 1)

    TriggerEvent("InteractSound_CL:PlayOnOne", "plane_takeoff", 1.0)
    TriggerEvent("InteractSound_CL:PlayOnOne", "cutscene_music", 0.5)

    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    AttachCamToEntity(cam, plane, -10.0, 0.0, 5.0, true)
    PointCamAtEntity(cam, plane, 0.0, 0.0, 0.0, true)
    RenderScriptCams(true, false, 0, true, true)

    DoScreenFadeIn(1000)

    TaskPlaneMission(pilot, plane, 0, 0, destination.coords.x, destination.coords.y, destination.coords.z + 100.0, 4, 100.0, 0.0, 0.0, 0.0, 100.0)

    Wait(10000)

    DoScreenFadeOut(1000)
    Wait(1500)

    -- find the arrival airport: pick the one closest to the destination
    -- (an exact distance threshold never matches, e.g. LS -> Sandy Shores is ~16.7 m apart)
    local arrivalAirport = nil
    local bestDist = math.huge
    for _, airport in pairs(Config.Airports) do
        local d = #(airport.coords - destination.coords)
        if d < bestDist then
            bestDist = d
            arrivalAirport = airport
        end
    end

    if arrivalAirport then
        local headingRad = math.rad(arrivalAirport.pedHeading)
        local offsetX = math.cos(headingRad) * -2.5
        local offsetY = math.sin(headingRad) * -2.5
        local newX = arrivalAirport.coords.x + offsetX
        local newY = arrivalAirport.coords.y + offsetY
        local newZ = arrivalAirport.coords.z
        SetEntityCoords(player, newX, newY, newZ, false, false, false, true)
        SetEntityHeading(player, arrivalAirport.pedHeading + 180.0)
    else
        SetEntityCoords(player, destination.coords.x, destination.coords.y, destination.coords.z, false, false, false, true)
    end

    Wait(1000)
    RenderScriptCams(false, false, 0, true, true)
    DestroyCam(cam, false)

    if DoesEntityExist(plane) then DeleteEntity(plane) end
    if DoesEntityExist(pilot) then DeleteEntity(pilot) end

    DoScreenFadeIn(1000)
 end

-- Event Handlers
RegisterNetEvent('zindro:openMenuForTarget', function(data)
    -- QB-Target passes data in args, so we need to extract it
    local airportIndex = nil
    if data and data.args and data.args.airportIndex then
        airportIndex = data.args.airportIndex
    elseif data and data.airportIndex then
        airportIndex = data.airportIndex
    end
    
    if not airportIndex then return end
    
    local airport = Config.Airports[airportIndex]
    if not airport then return end
    OpenAirportMenu(airport)
end)

RegisterNetEvent('zindro:travelOptionSelected', function(data)
    if not data or not data.destination or not data.departure then return end
    isInMenu = false
    StartTravelSequence(data.destination, data.departure)
end)

RegisterCommand("testsound", function()
    TriggerEvent("InteractSound_CL:PlayOnOne", "demo", 1.0)
end, false)

-- Test command to manually open menu
RegisterCommand("testmenu", function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    for idx, airport in pairs(Config.Airports) do
        local dist = #(playerCoords - airport.coords)
        if dist < 10.0 then
            print("^2[zindro-airtravel]^7 Testing menu for airport:", airport.name)
            OpenAirportMenu(airport)
            return
        end
    end
    print("^1[zindro-airtravel]^7 No airport found nearby for testing")
end, false)

-- Main Threads
Citizen.CreateThread(function()
    for idx, airport in pairs(Config.Airports) do
        RequestModel(airport.pedModel)
        while not HasModelLoaded(airport.pedModel) do Wait(0) end

        local ped = CreatePed(4, airport.pedModel, airport.coords.x, airport.coords.y, airport.coords.z - 1.0, airport.pedHeading, false, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)

        airport.ped = ped
        pedToAirport[ped] = idx

        -- blip
        local blip = AddBlipForCoord(airport.coords)
        SetBlipSprite(blip, 90)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.9)
        SetBlipColour(blip, 3)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Airfield Travel")
        EndTextCommandSetBlipName(blip)

        -- qb-target integration
        if GetResourceState('qb-target') == 'started' then
            print("^2[zindro-airtravel]^7 Adding qb-target for airport:", airport.name)
            exports['qb-target']:AddTargetEntity(ped, {
                options = {
                    {
                        type = "client",
                        event = "zindro:openMenuForTarget",
                        icon = "fas fa-plane",
                        label = "Speak to Pilot",
                        args = { airportIndex = idx }
                    }
                },
                distance = 2.5
            })
            activeTargets[#activeTargets + 1] = ped
            print("^2[zindro-airtravel]^7 qb-target added successfully for airport:", airport.name)
        else
            print("^1[zindro-airtravel]^7 qb-target not found, using proximity fallback")
        end
    end
end)

-- proximity fallback if qb-target missing or for servers that prefer it
Citizen.CreateThread(function()
    while true do
        local waitTime = 1000
        if GetResourceState('qb-target') ~= 'started' then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            for _, airport in pairs(Config.Airports) do
                local dist = #(playerCoords - airport.coords)
                if dist < 2.5 then
                    waitTime = 0
                    DrawText3D(airport.coords.x, airport.coords.y, airport.coords.z + 1.0, "[E] Speak to Pilot")
                    if IsControlJustReleased(0, 38) then
                        OpenAirportMenu(airport)
                    end
                end
            end
        end
        Citizen.Wait(waitTime)
    end
end)
