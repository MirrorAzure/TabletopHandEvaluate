--[[ Lua code. See documentation: https://api.tabletopsimulator.com/ --]]

version = "0.2"

--players = getColors()

pairCards = {
    "crab",
    "fish",
    "boat"
}

collectorValues = {
    shell   = {0, 2, 4, 6, 8, 10},
    octopus = {0, 3, 6, 9, 12},
    penguin = {1, 3, 5},
    sailor  = {0, 5}
}

function getCollectorValue(args)
    --[[
        Facade for collector cards
        -- Not really useful, but you may add custom logic (e.g. adding extra points for extended decks)
        Args:
            - collectorType  : name of collector
            - collectorCount : number of collector cards
        Returns:
            - value          : number of points player get
    --]]
    local collectorType = args["collectorType"]
    local collectorCount = args["collectorCount"]
    local values = collectorValues[collectorType]
    if not values then return 0 end
    if collectorCount > #values then
        return values[#values]
    end
    return values[collectorCount]
end

multiplierValues = {
    crab    = 1,
    fish    = 1,
    boat    = 1,
    penguin = 2,
    sailor  = 3
}

--[[ The onLoad event is called after the game save finishes loading. --]]
function onLoad()
    --[[ print('onLoad!') --]]
    print("Hand evaluate (v" .. version .. ") by MirrorAzure")
end

--[[ The onUpdate event is called once per frame. --]]
function onUpdate()
    --[[ print('onUpdate loop!') --]]
end