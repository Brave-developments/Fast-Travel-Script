-- config.lua
Config = {}

Config.Airports = {
    {
        name = "Los Santos International Airport",
        coords = vector3(-1043.09, -2746.84, 21.36),
        pedHeading = 330.0,
        pedModel = "s_m_m_pilot_01",
        planeSpawn = vector4(-1334.0, -3265.0, 13.5, 60.0),
        destinations = {
            {label = "Sandy Shores Airfield", coords = vector3(1780.30, 3320.96, 41.36)},
            {label = "Grapeseed Airfield", coords = vector3(2130.0, 4796.0, 41.1)}
        }
    },
    {
        name = "Sandy Shores Airfield",
        coords = vector3(1758.79, 3297.81, 41.15),
        pedHeading = 195.0,
        pedModel = "s_m_m_pilot_01",
        planeSpawn = vector4(1691.0, 3265.0, 41.1, 55.0),
        destinations = {
            {label = "Los Santos International", coords = vector3(-1033.60, -2733.62, 20.17)},
            {label = "Grapeseed Airfield", coords = vector3(2130.0, 4796.0, 41.1)}
        }
    },
    {
        name = "Grapeseed Airfield",
        coords = vector3(2158.89, 4789.98, 41.12),
        pedHeading = 45.0,
        pedModel = "s_m_m_pilot_01",
        planeSpawn = vector4(2134.0, 4836.0, 101.1, 45.0),
        destinations = {
            {label = "Los Santos International", coords = vector3(-1033.60, -2733.62, 20.17)},
            {label = "Sandy Shores Airfield", coords = vector3(1780.30, 3320.96, 41.36)}
        }
    }
}
