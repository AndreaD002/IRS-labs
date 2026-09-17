MAX_VELOCITY     = 15    -- default
PROX_THRESHOLD   = 0.2   -- distance to avoid obstacles
LIGHT_DEADBAND   = 0.01  -- to avoid squiggle movements in a noisy enviorment
LIGHT_THRESHOLD  = 0.02  -- used to visualize the difference between random walk and phototaxis
GROUND_THRESHOLD = 0.1   -- to halt the robot on a dark ground

escape = false  -- used to escape from narrow spots
escape_dir = 0  -- to sample a random escape direction

function init()
    escape = false
    escape_dir = 0
    robot.wheels.set_velocity(0, 0)
    robot.leds.set_all_colors("black")
end

-- Returns the max value among the sensors in the given range 
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

-- Returns the min value among the sensors in the given range 
function min_in_range(sensor, first_idx, last_idx, step)
    local min_val = 1e9
    step = step or 1
    for i = first_idx, last_idx, step do
        if sensor[i].value < min_val then
            min_val = sensor[i].value
        end
    end
    return min_val
end

-- Reads all the relevant sensors and compute the values needed
function sense()
    local s = {}

    s.prox_left  = max_in_range(robot.proximity, 1, 6, 1)    -- left side reading
    s.prox_right = max_in_range(robot.proximity, 19, 24, 1)  -- right side reading
    s.prox_front = math.max(s.prox_left, s.prox_right)

    s.light_left  = max_in_range(robot.light, 1, 12, 1)      -- left side reading
    s.light_right = max_in_range(robot.light, 13, 24, 1)     -- right side reading
    s.light_seen  = math.max(s.light_left, s.light_right) > LIGHT_THRESHOLD  -- enough light means light seen

    s.ground_min = min_in_range(robot.motor_ground, 1, 4, 1) -- ground reading
    s.on_target  = (s.ground_min < GROUND_THRESHOLD)

    return s
end

-- Creates the command to be executed
function make_cmd(left, right, color)
    return {
        left = left,
        right = right,
        color = color or "black"
    }
end

-- Layer 0: default motion (Lowest priority)
function layer_wander(s)
    return make_cmd(MAX_VELOCITY, MAX_VELOCITY, "blue") -- straight movement
end

-- Layer 1: phototaxis
function layer_phototaxis(s, cmd)
    local diff = s.light_right - s.light_left

    if not s.light_seen then
        return cmd
    elseif math.abs(diff) <= LIGHT_DEADBAND then
        return make_cmd(MAX_VELOCITY, MAX_VELOCITY, "yellow")
    elseif diff > 0 then
        return make_cmd(MAX_VELOCITY, 0, "yellow")
    else
        return make_cmd(0, MAX_VELOCITY, "yellow")
    end
end

-- Layer 2: obstacle avoidance with escape recovery
function layer_avoid(s, cmd)
    if escape then
        if s.prox_front <= PROX_THRESHOLD then
            escape = false
            return cmd
        end

        if escape_dir == 1 then
            return make_cmd(MAX_VELOCITY / 2, -MAX_VELOCITY / 2, "red")
        else
            return make_cmd(-MAX_VELOCITY / 2, MAX_VELOCITY / 2, "red")
        end
    end

    if s.prox_left > PROX_THRESHOLD and s.prox_right > PROX_THRESHOLD then
        escape = true
        if robot.random.uniform() < 0.5 then
            escape_dir = 0
        else
            escape_dir = 1
        end

        if escape_dir == 1 then
            return make_cmd(MAX_VELOCITY / 2, -MAX_VELOCITY / 2, "red")
        else
            return make_cmd(-MAX_VELOCITY / 2, MAX_VELOCITY / 2, "red")
        end
    end

    if s.prox_front > PROX_THRESHOLD then
        if s.prox_left > s.prox_right then
            return make_cmd(MAX_VELOCITY / 2, -MAX_VELOCITY / 2, "red")
        else
            return make_cmd(-MAX_VELOCITY / 2, MAX_VELOCITY / 2, "red")
        end
    end

    return cmd
end

-- Layer 4: stop on the black spot (Highest priority)
function layer_halt(s, cmd)
    if s.on_target then
        return make_cmd(0, 0, "green")
    end
    return cmd
end

-- Apply the command to the actuators
function apply_command(cmd)
    robot.leds.set_all_colors(cmd.color)
    robot.wheels.set_velocity(cmd.left, cmd.right)
end

-- Sense the enviorment and apply behaviours in increasing priority order
-- (higher layers have bigger priority and may override (subsume) lower layers) 
function step()
    local s = sense()

    local cmd = layer_wander(s)
    cmd = layer_phototaxis(s, cmd)
    cmd = layer_avoid(s, cmd)
    cmd = layer_halt(s, cmd)

    apply_command(cmd)
end

function reset()
    init()
end

function destroy()
end
