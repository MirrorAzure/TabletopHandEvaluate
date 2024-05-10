--[[
    Hand Evaluate v0.1 by MirrorAzure
    github: https://github.com/MirrorAzure/TabletopHandEvaluate
    steam workshop: coming soon maybe
    
    This script is to be loaded to each player's hand object
--]]

function onLoad()
    resetHand()
end

function resetHand()
    --[[
        Resets hand state
    --]]
    cardCount = {}
    colorCount = {}
    multipliers = {}
    collectors = {}
    cardPairs = 0
    points = 0
    setMeta()
    setHand()
    evalHand()
    displayPoints()
end

function setHand()
    --[[
        Get all hands in hand and evaluate them
    --]]
    local hand = Player[zoneColor].getHandObjects(1)
    for i, object in ipairs(hand) do
        if object.tag == "Card" then
            addCard(object)
        end
    end  
end

function setMeta()
    --[[
        Sets all zone metadata (unification for xml ui)
    --]]
    zoneColor = self.getData()["FogColor"]
    ui_points_id = "points_" .. zoneColor
end

function displayPoints()
    --[[
        Changes UI to display current points
    --]]
    local pointsString = "Your Score: " .. points
    UI.setValue(ui_points_id, pointsString)
end

function onObjectEnterZone(zone, object)
    --log("DEBUG: Object " .. object.guid .. " entered zone " .. zone.guid)
    if zone == self then
        addCard(object)
        evalHand()
        displayPoints()
    end
end

function onObjectLeaveZone(zone, object)
    --log("DEBUG: Object " .. object.guid .. " left")
    if zone == self then
        removeCard(object)
        evalHand()
        displayPoints()
    end
end

function addCardType(cardType)
    --[[
        Handles adding cards to cardCount
    --]]
    if not cardCount[cardType] then
        cardCount[cardType] = 1
    else
        cardCount[cardType] = cardCount[cardType] + 1
    end
end

function addCardColor(cardColor)
    --[[
        Handles adding colors to colorCount
    --]]
    if not colorCount[cardColor] then
        colorCount[cardColor] = 1
    else
        colorCount[cardColor] = colorCount[cardColor] + 1
    end
end

function addMultiplier(multiplierType)
    --[[
        Handles adding multipliers
    --]]
    if multiplierType then
        table.insert(multipliers, multiplierType)
    end
end

function addCard(card)
    local cardType = card.getVar("cardType")
    local cardColor = card.getVar("cardColor")
    local multiplierType = card.getVar("multiplierType")
    addCardType(cardType)
    addCardColor(cardColor)
    addMultiplier(multiplierType)
    --log("DEBUG: " .. cardColor .. " " .. cardType .. " " .. "added")
end

function removeCardType(cardType)
    --[[
        Handles removing cards from cardCount
    --]]
    cardCount[cardType] = cardCount[cardType] - 1
    if cardCount[cardType] == 0 then cardCount[cardType] = nil end
end

function removeCardColor(cardColor)
    --[[
        Handles removing colors to colorCount
    --]]
    colorCount[cardColor] = colorCount[cardColor] - 1
    if colorCount[cardColor] == 0 then colorCount[cardColor] = nil end
end

function removeMultiplier(multiplierType)
    --[[
        Handles removing multipliers
    --]]
    if multiplierType then
        for index, multiplier in ipairs(multipliers) do
            if multiplier == multiplierType then
                table.remove(multipliers, index)
            end
        end
    end
end

function removeCard(card)
    local cardType = card.getVar("cardType")
    local cardColor = card.getVar("cardColor")
    local multiplierType = card.getVar("multiplierType")
    removeCardType(cardType)
    removeCardColor(cardColor)
    removeMultiplier(multiplierType)
    --log("DEBUG: " .. cardColor .. " " .. cardType .. " " .. "removed")
end

function getMostCommonColor(topK)
    --[[
        Calculate total number of most common colors in hand
        Args:
            - topK  : number of colors
        Returns:
            - total : count of K most common color cards
    --]]
    local total = 0
    local leftColors = {}
    for color, count in pairs(colorCount) do
        --log("DEBUG: color: " .. color .. " | " .. "count: " .. count )
        leftColors[color] = count
    end
    local counter = topK
    while counter > 0 do
        local maximum = 0
        local maximum_color = nil
        for color, count in pairs(leftColors) do
            if count >= maximum then
                maximum = count
                maximum_color = color
            end
        end
        if not maximum_color then break end
        total = total + maximum
        leftColors[maximum_color] = nil
        counter = counter - 1
    end
    return total
end

function getMissedCollectorValue(topK)
    --[[
        Calculate value player missing for collector cards
        Args:
            - topK  : number of missing cards to search
        Returns:
            - total : sum of top K missing values
    --]]
    local total = 0
    local currentCards = {}
    for card, count in pairs(cardCount) do
        --log("DEBUG: card: " .. tostring(card) .. " | " .. "count: " .. tostring(count) )
        currentCards[card] = count
    end
    local collectorValues = Global.getVar("collectorValues")
    local counter = topK
    while counter > 0 do
        local maximum = 0
        local maximum_type = nil
        for key, values in pairs(collectorValues) do
            local collector = cardCount[key]
            if collector then
                local value = Global.call("getCollectorValue", {collectorType=key, collectorCount=collector})
                local missedValue = Global.call("getCollectorValue", {collectorType=key, collectorCount=(collector + 1)}) - value
                if maximum < missedValue then
                    maximum = missedValue
                    maximum_type = key
                end
            end
        end
        if not maximum_type then break end
        total = total + maximum
        currentCards[maximum_type] = currentCards[maximum_type] + 1
        counter = counter - 1
    end
    return total
end

function evalHand()
    --[[
        Calculate all points in hand
    --]]
    points = 0
    cardPairs = 0
    -- Apply mermaid color bonus
    local mermaids = cardCount["mermaid"]
    if mermaids then
        points = points + getMostCommonColor(mermaids)
    end
    
    -- Apply multiplier bonus
    local multiplierValues = Global.getVar("multiplierValues")
    for index = 1, #multipliers do
        local multiplier = multipliers[index]
        if cardCount[multiplier] then
            points = points + cardCount[multiplier] * multiplierValues[multiplier]
        end
    end
    
    -- Apply collector bonus
    local collectorValues = Global.getVar("collectorValues")
    for key, values in pairs(collectorValues) do
        local collector = cardCount[key]
        if collector then
            points = points + Global.call("getCollectorValue", {collectorType=key, collectorCount=collector})
        end
    end
    
    -- Apply seahorse bonus
    local seahorses = cardCount["seaHorse"]
    if seahorses then
        points = points + getMissedCollectorValue(seahorses)
    end
    
    -- Apply pair bonus
    local pairCards = Global.getVar("pairCards")
    for index = 1, #pairCards do
        local paired = pairCards[index]
        if cardCount[paired] then
            local pairCount = (cardCount[paired] / 2)
            pairCount = pairCount - pairCount%1
            cardPairs = cardPairs + pairCount
        end
    end
    
    -- Special case: Lobster + Crab is  a pair
    local crabs = cardCount["crab"]
    local lobsters = cardCount["lobster"]
    
    if crabs and lobsters then
        local unpairedCrabs = crabs % 2
        cardPairs = cardPairs + math.min(lobsters, unpairedCrabs)
    end
    
    -- Special case: Shark / Jellyfish + Swimmer is a pair
    local swimmers = cardCount["swimmer"]
    local sharks = cardCount["shark"]
    local jellyfishes = cardCount["jellyfish"]
    
    if swimmers then
        if not sharks then sharks = 0 end
        if not jellyfishes then jellyfishes = 0 end
        cardPairs = cardPairs + math.min(swimmers, (sharks + jellyfishes))
    end
    
    -- Apply starfish bonus
    local starfishes = cardCount["starfish"]
    if not starfishes then starfishes = 0 end
    while (starfishes > 0) and (cardPairs > 0) do
        starfishes = starfishes - 1
        cardPairs = cardPairs - 1
        points = points + 3
    end
    
    points = points + cardPairs
end