MAX_VELOCITY   = 15    -- maximum allowed wheel speed
PROX_THRESHOLD = 0.2   -- obstacle avoidance activation threshold
LIGHT_DEADBAND = 0.01  -- ignore very small light differences

left_v  = 0
right_v = 0

escape = false         -- used to recover when both sides are blocked
escape_dir = 0         -- 0 = turn left, 1 = turn right

function init()
    left_v = MAX_VELOCITY
    right_v = MAX_VELOCITY

    robot.wheels.set_velocity(left_v, right_v)
    robot.leds.set_all_colors("black")

    escape = false
    escape_dir = 0
end

-- Returns the maximum value in a sensor range
function max_in_range(sensor, first_idx, last_idx, step)
    local max_val = -1
    step = step or 1

    for i = first_idx, last_idx, step do
        if sensor[i].value > max_val then
            max_val = sensor[i].value
        end
    end

    return max_val
end

function step()
    -- Proximity readings
    local prox_left  = max_in_range(robot.proximity, 1, 6, 1)
    local prox_right = max_in_range(robot.proximity, 24, 19, -1)
    local prox_front = math.max(prox_left, prox_right)

    -- Light readings
    local light_left  = max_in_range(robot.light, 1, 12, 1)
    local light_right = max_in_range(robot.light, 13, 24, 1)

    -- Enter escape mode when both sides are blocked
    if (not escape) and prox_left > PROX_THRESHOLD and prox_right > PROX_THRESHOLD then
        escape = true

        if robot.random.uniform() < 0.5 then
            escape_dir = 0
        else
            escape_dir = 1
        end
    end

    -- Escape behavior
    if escape then
        if prox_front <= PROX_THRESHOLD then
            robot.leds.set_all_colors("black")
            escape = false
        else
            robot.leds.set_all_colors("red")

            if escape_dir == 1 then
                left_v = MAX_VELOCITY / 2
                right_v = -MAX_VELOCITY / 2
            else
                left_v = -MAX_VELOCITY / 2
                right_v = MAX_VELOCITY / 2
            end
        end
    end

    -- Standard behavior
    if not escape then
        if prox_front > PROX_THRESHOLD then
            -- Turn away from the closest obstacle
            robot.leds.set_all_colors("red")

            if prox_left > prox_right then
                left_v = MAX_VELOCITY / 2
                right_v = -MAX_VELOCITY / 2
            else
                left_v = -MAX_VELOCITY / 2
                right_v = MAX_VELOCITY / 2
            end

        elseif light_right > light_left and (light_right - light_left) > LIGHT_DEADBAND then
            -- Steer right toward the light
            robot.leds.set_all_colors("green")
            left_v = MAX_VELOCITY
            right_v = 0

        elseif light_left > light_right and (light_left - light_right) > LIGHT_DEADBAND then
            -- Steer left toward the light
            robot.leds.set_all_colors("green")
            left_v = 0
            right_v = MAX_VELOCITY

        else
            -- Default forward motion
            robot.leds.set_all_colors("blue")
            left_v = MAX_VELOCITY
            right_v = MAX_VELOCITY
        end
    end

    -- Slow down when approaching the light
    local mean_light = (light_right + light_left) / 2
    local factor = 1 - mean_light

    robot.wheels.set_velocity(factor * left_v, factor * right_v)
end

function reset()
    init()
end

function destroy()
end
