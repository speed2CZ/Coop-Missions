local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')

function ChooseRandomBases()
    if not ScenarioInfo.MissionNumber then
        error('*RANDOM BASE: ScenarioInfo.MissionNumber needs to be set.')
    end

    local currentMissionBases = ScenarioInfo.OperationScenarios['M' .. ScenarioInfo.MissionNumber].Bases

    if not currentMissionBases then
        error('*RANDOM BASE: No bases specified for mission number: ' .. ScenarioInfo.MissionNumber, 2)
    end

    for name, base in currentMissionBases do
        local num = Random(1, table.getn(base.Types))
        LOG('*RANDOM BASE: Name: ' .. tostring(name) .. ', type: ' .. base.Types[num])
        if base.CallFunction then
            base.CallFunction(base.Types[num])
        end
    end
end

function ChooseRandomEvent(useDelay)
    local data = ScenarioInfo.OperationScenarios
    local num = ScenarioInfo.MissionNumber

    -- Table with events for current mission number
    local currentEvents = data['M' .. num].Events

    if not data then
        error('*RANDOM EVENT: ScenarioInfo.OperationScenarios does not exist.')
    elseif not num then
        error('*RANDOM EVENT: ScenarioInfo.MissionNumber needs to be set.')
    elseif not currentEvents or table.getn(currentEvents) == 0 then
        error('*RANDOM EVENT: No events specified for mission number: ' .. num .. ', inside "M' .. num .. '" table')
    end
    
    -- Randomly pick one event
    local function PickEvent(tblEvents)
        local availableEvents = {}
        local event

        -- Check available events
        for _, event in tblEvents do
            if not event.Used then
                table.insert(availableEvents, event)
            end
        end

        -- Pick one, mark as used
        local num = table.getn(availableEvents)

        if num ~= 0 then
            local event = availableEvents[Random(1, num)]
            event.Used = true

            return event
        else
            -- Reset availability and try to pick again
            for _, event in tblEvents do
                event.Used = false
            end
            PickEvent(tblEvents)
        end
    end

    local event = PickEvent(currentEvents)

    -- LOG('*speed2: RANDOM EVENT: Mission Number: ' .. num .. ', chosen event: ' .. event.Log)
    LOG(repr(currentEvents))

    ForkThread(StartEvent, event, num, useDelay)
end

-- If we have a delay table, we have various possible ways
-- { { eNum1, eNum2 }, { mNum1, mNum2 }, { hNum1, hNum2 } } - This is a difficulty defined random delay
-- { eNum, mNum, hNum } - This is a difficulty defined delay
-- { Num,1 Num2 } - This is a random delay
-- Num - This is the delay
function StartEvent(event, missionNumber, useDelay)
    if useDelay then
        local num
        local tblDelay = event.Delay
        local Difficulty = ScenarioInfo.Options.Difficulty

        if type(tblDelay) == 'table' then

            -- Table of tables means to use Random() on the inner table to get always slightly different delay
            if type(tblDelay[1]) == 'table' then
                num = Random(tblDelay[Difficulty][1], tblDelay[Difficulty][2])

            -- Table with 3 entries is a dificulty table
            elseif table.getn(tblDelay) == 3 then
                num = tblDelay[Difficulty]

            -- Table with 2 entries to use Random() on them
            elseif table.getn(tblDelay) == 2 then
                num = Random(tblDelay[1], tblDelay[2])

            -- Unknown number of entries
            else
                error('*RANDOM EVENT: Unknown number of entries passed to Delay')
            end
        else
            -- Last option is a single number
            num = tblDelay
        end

        LOG('*speed2: RANDOM EVENT: Delay: ' .. num)
        WaitSeconds(num)
    end

    -- Check if the mission didn't end while we were waiting
    if not ScenarioInfo.MissionNumber == missionNumber then
        return
    end

    event.CallFunction()
end

-- TODO: Create new build location with carrier.
function CarrierAI(platoon)
    platoon:Stop()
    local aiBrain = platoon:GetBrain()
    local data = platoon.PlatoonData
    local carriers = platoon:GetPlatoonUnits()
    local movePositions = {}

    if(data) then
        if(data.MoveRoute or data.MoveChain) then
            if data.MoveChain then
                movePositions = ScenarioUtils.ChainToPositions(data.MoveChain)
            else
                for k, v in data.MoveRoute do
                    if type(v) == 'string' then
                        table.insert(movePositions, ScenarioUtils.MarkerToPosition(v))
                    else
                        table.insert(movePositions, v)
                    end
                end
            end

            local numCarriers = table.getn(carriers)
            local numPositions = table.getn(movePositions)

            if numCarriers <= numPositions then
                for i = 1, numCarriers do
                    ForkThread(function(i)
                        IssueMove( {carriers[i]}, movePositions[i] )

                        while (carriers[i] and not carriers[i]:IsDead() and carriers[i]:IsUnitState('Moving')) do
                            WaitSeconds(.5)
                        end

                        local location
                        for num, loc in aiBrain.PBM.Locations do
                            if loc.LocationType == data.Location .. i then
                                location = loc
                                break
                            end
                        end

                        if not carriers[i]:IsDead() then
                            location.PrimaryFactories.Air = carriers[i]
                        end

                        while (carriers[i] and not carriers[i]:IsDead()) do
                            if  table.getn(carriers[i]:GetCargo()) > 0 and carriers[i]:IsIdleState() then
                                IssueClearCommands(carriers[i])
                                IssueTransportUnload({carriers[i]}, carriers[i]:GetPosition())
                            end
                            WaitSeconds(1)
                        end
                    end, i)
                end             
            else
                error('*Carrier AI ERROR: Less move positions than carriers', 2)
            end
        else
            error('*Carrier AI ERROR: MoveToRoute or MoveChain not defined', 2)
        end
    else
        error('*Carrier AI ERROR: PlatoonData not defined', 2)
    end
end

function PatrolThread(platoon)
    local data = platoon.PlatoonData

    if(data.Carrier) then
        for _, unit in platoon:GetPlatoonUnits() do
            while (not unit:IsDead() and unit:IsUnitState('Attached')) do
                WaitSeconds(1)
            end
        end
    end

    platoon:Stop()
    if(data) then
        if(data.PatrolRoute or data.PatrolChain) then
            if data.PatrolChain then
                ScenarioFramework.PlatoonPatrolRoute(platoon, ScenarioUtils.ChainToPositions(data.PatrolChain))
            else
                for k,v in data.PatrolRoute do
                    if type(v) == 'string' then
                        platoon:Patrol(ScenarioUtils.MarkerToPosition(v))
                    else
                        platoon:Patrol(v)
                    end
                end
            end
        else
            error('*SCENARIO PLATOON AI ERROR: PatrolRoute or PatrolChain not defined', 2)
        end
    else
        error('*SCENARIO PLATOON AI ERROR: PlatoonData not defined', 2)
    end
end