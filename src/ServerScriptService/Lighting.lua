local TICKS_PER_MINUTE = 20
local STARTING_HOUR = 9
local MINUTES_PER_DAY = 24 * 60
local Lighting = game:GetService("Lighting")

local function tick()
    local minutesAfterMidnight = STARTING_HOUR * 60
    local waitTime = TICKS_PER_MINUTE / 60

    while true do
        minutesAfterMidnight += 1
        minutesAfterMidnight %= MINUTES_PER_DAY
        Lighting:SetMinutesAfterMidnight(minutesAfterMidnight)
        task.wait(waitTime)
    end
end

return {
    tick = tick,
}
