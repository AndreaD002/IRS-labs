local S        = 0.01   -- spontaneous stopping probability
local W        = 0.85   -- spontaneous walking probability
local PSmax    = 0.99   -- maximum stopping probability
local PWmin    = 0.005  -- minimum walking probability
local alpha    = 0.85    -- weight of neighbours on Ps
local beta     = 0.19    -- weight of neighbours on Pw
local MAXRANGE = 35     -- RAB sensing range in cm

local MAX_VELOCITY   = 15    -- max wheel speed
local PROX_THRESHOLD = 0.9   -- obstacle avoidance activation threshold

local STATE_MOVING  = 0
local STATE_STOPPED = 1
local state = STATE_MOVING


-- Count nearby stopped robots via RAB
function CountRAB()
   local count = 0
   for i = 1, #robot.range_and_bearing do
      if robot.range_and_bearing[i].range < MAXRANGE and
         robot.range_and_bearing[i].data[1] == 1 then
         count = count + 1
      end
   end
   return count
end

-- Returns the maximum sensor value in a given index range
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

-- Random walk with obstacle avoidance (called only in STATE_MOVING)
function MoveWithAvoidance()
   local prox_left  = max_in_range(robot.proximity, 1,  6,  1)
   local prox_right = max_in_range(robot.proximity, 24, 19, -1)
   local prox_front = math.max(prox_left, prox_right)

   local left_v  = MAX_VELOCITY
   local right_v = MAX_VELOCITY

   if prox_front > PROX_THRESHOLD then
      -- Turn away 
      robot.leds.set_all_colors("yellow")
      if prox_left > prox_right then
         left_v  =  MAX_VELOCITY 
         right_v = -MAX_VELOCITY 
      else
         left_v  = -MAX_VELOCITY 
         right_v =  MAX_VELOCITY 
      end
   else
      -- Random walk
      robot.leds.set_all_colors("red")
      local r = robot.random.uniform()
      if r < 0.08 then
         left_v  =  MAX_VELOCITY
         right_v = 0   -- turn right
      elseif r < 0.15 then
         left_v  = 0
         right_v =  MAX_VELOCITY   -- turn left
      else
         left_v  = MAX_VELOCITY        -- go straight
         right_v = MAX_VELOCITY
      end
   end

   robot.wheels.set_velocity(left_v, right_v)
end


function init()
   state = STATE_MOVING
   robot.range_and_bearing.set_data(1, 0)
   robot.leds.set_all_colors("red")
end

function step()
   local N  = CountRAB()
   local Ps = math.min(PSmax, S + alpha * N)
   local Pw = math.max(PWmin, W - beta  * N)

   if state == STATE_MOVING then
      robot.range_and_bearing.set_data(1, 0)  -- broadcast: moving

      local t = robot.random.uniform()
      if t <= Ps then
         state = STATE_STOPPED
         robot.wheels.set_velocity(0, 0)
      else
         MoveWithAvoidance()
      end

   elseif state == STATE_STOPPED then
      robot.wheels.set_velocity(0, 0)
      robot.range_and_bearing.set_data(1, 1)  -- broadcast: stopped
      robot.leds.set_all_colors("green")

      local t = robot.random.uniform()
      if t <= Pw then
         state = STATE_MOVING
      end
   end
end

function reset()
   init()
end

function destroy()
end