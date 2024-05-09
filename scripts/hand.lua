function onLoad()
    resetHand()
end

function resetHand()
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
    local hand = Player[zoneColor].getHandObjects(1)
    for i, object in ipairs(hand) do
        if object.tag == "Card" then
            addCard(object)
        end
    end  
end

function setMeta()
    zoneColor = self.getData()["FogColor"]
    ui_points_id = "points_" .. zoneColor
end

function displayPoints()
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
    if not cardCount[cardType] then
        cardCount[cardType] = 1
    else
        cardCount[cardType] = cardCount[cardType] + 1
    end
end

function addCardColor(cardColor)
    if not colorCount[cardColor] then
        colorCount[cardColor] = 1
    else
        colorCount[cardColor] = colorCount[cardColor] + 1
    end
end

function addMultiplier(multiplierType)
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
    local cardTypeCount = cardCount[cardType]
    if not cardTypeCount or cardTypeCount == 0 then
        cardCount[cardType] = 0
    else
        cardCount[cardType] = cardCount[cardType] - 1
    end
end

function removeCardColor(cardColor)
    local cardColorCount = colorCount[cardColor]
    if not cardColorCount or cardColorCount == 0 then
        colorCount[cardColor] = 0
    else
        colorCount[cardColor] = colorCount[cardColor] - 1
    end
end

function removeMultiplier(multiplierType)
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
        total = total + maximum
        leftColors[maximum_color] = nil
        counter = counter - 1
    end
    return total
end

function evalHand()
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
        if collector and collector ~= 0 then
            points = points + values[collector]
        end
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
    
    -- Special case: Shark + Swimmer is a pair
    local swimmers = cardCount["swimmer"]
    local sharks = cardCount["shark"]
    if swimmers and sharks then
        cardPairs = cardPairs + math.min(swimmers, sharks)
    end
    points = points + cardPairs
end