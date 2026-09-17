local vector = require "vector"

MAX_VELOCITY     = 15  -- set by default instructions
REPULSIVE_WEIGHT = 10  -- to avoid getting too close to objects

L = 0  -- wheel axis length in metres, set in init()

function init()
    L = robot.wheels.axis_length   
    robot.wheels.set_velocity(0, 0)
    robot.leds.set_all_colors("black")
end

-- Motor Schemas

-- ATTRACTIVE (used for light)
function schema_attractive()
    local acc   = {length = 0.0, angle = 0.0}
    local total = 0.0                          -- sum of individual magnitudes
    for i = 1, 24 do
        local s = robot.light[i]
        if s.value > 0 then
            acc   = vector.vec2_polar_sum(acc, {length = s.value, angle = s.angle})
            total = total + s.value            -- accumulate scalar sum
        end
    end
    if total > 0 then
        acc.length = (acc.length / total)
    end
    return acc
end

-- Returns the opposite of a polar vector (same length, opposite angle)
local function negate(v)
   local a = v.angle + math.pi
   if a > math.pi then a = a - 2 * math.pi end  -- normalised between -pi and +pi
   return {length = v.length, angle = a}
end

-- REPULSIVE (used for obstacles)
function schema_repulsive()
    local acc   = {length = 0.0, angle = 0.0}
    local total = 0.0
    for i = 1, 24 do
        local s = robot.proximity[i]
        if s.value > 0 then
            acc = vector.vec2_polar_sum(acc, negate({length = s.value, angle = s.angle})) -- sum vectors with opposite direction of the relative sensor
            total = total + s.value
        end
    end
    if total > 0 then
        acc.length = (acc.length / total) * REPULSIVE_WEIGHT
    end
    return acc
end

-- WANDER
function schema_wander()
    local rand_length = robot.random.uniform(0.5, 1.0) -- random magnitude to escape local minima
    return {length = rand_length, angle = 0.0}
end


-- Applies the final vector to the wheels actuators
function result_to_wheels(result)
    local v      = MAX_VELOCITY*result.length  
    local omega  = result.angle
    local half_L = (L * 100) / 2

    local vl = v - half_L * omega
    local vr = v + half_L * omega

    vl = math.max(0, math.min(MAX_VELOCITY, vl))
    vr = math.max(0, math.min(MAX_VELOCITY, vr))
    return vl, vr
end

function step()
    -- Compute each schema vector
    local v_wander  = schema_wander()
    local v_attract = schema_attractive()
    local v_repulse = schema_repulsive()
    
    -- Vector summation (all schemas act simultaneously)
    local result = {length = 0.0, angle = 0.0}
    result = vector.vec2_polar_sum(result, v_wander)
    result = vector.vec2_polar_sum(result, v_attract)
    result = vector.vec2_polar_sum(result, v_repulse)

    -- Apply to wheels
    local vl, vr = result_to_wheels(result)
    robot.wheels.set_velocity(vl, vr)
end

function reset()
    init()
end

function destroy()
end
