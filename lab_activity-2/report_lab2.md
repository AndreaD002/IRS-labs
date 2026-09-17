# Lab 2 Report 
## Andrea Dotti

The idea behind this controller comes from Braitenberg vehicles: instead of writing a long chain of conditions that tell the robot exactly what to do in every situation, the sensors are connected directly to the wheels through simple rules, and the behavior just emerges from that. This gives the robot more freedom to **react** naturally to whatever it finds in the environment, without being over-controlled.

The controller implements four behaviors : 
- escape mode (which could be collapsed into obstacle)
- obstacle avoidance
- phototaxis
- wandering

They interact through a simple priority stack (higher to lower).

Wandering is the default: when no obstacle is close and the light difference between sides is below a small threshold, the robot just moves straight forward at full speed. This is a deliberate choice over a random walk, since the environment is closed, so straight motion covers more ground efficiently and keeps the robot within range of the light source. In an open world this wouldn't be ideal, but here it works well.

Phototaxis activates when the light intensity difference between the left and right sides exceeds the deadband threshold. Without it, sensor noise would cause continuous micro-corrections, and even with the light perfectly ahead the robot could start oscillating. When the difference is below the threshold, the robot simply falls back to the straight wandering motion, since it keeps moving efficiently toward the source without unnecessary turning. The crossed wheel logic mirrors Braitenberg's attraction coupling: the brighter side slows its wheel, steering the robot toward the source.

There's also a continuous speed scaling applied on top of everything else: the average light intensity is used to compute a factor (1 - mean_light) that scales both wheel velocities down as the robot gets closer to the source, naturally preventing overshooting. No hard stop threshold was added, as a fixed value would need careful tuning for different light configurations (height, intensity, distance). Staying close without fully stopping is good enough for the task and keeps the behavior general.

Obstacle avoidance kicks in when proximity readings exceed a threshold on either side, and it takes priority over phototaxis. The threshold here serves to define the activation range of the avoidance behavior. When an obstacle is detected, the robot turns away from the nearest side by reversing the opposite wheels, which is the same reactive sensor-to-motor logic Braitenberg describes for avoidance.

Escape mode handles the edge case where obstacles are detected on both sides simultaneously, like a corner or narrow corridor where a simple turn wouldn't help. The robot randomly picks a rotation direction and spins in place until the front clears. Conceptually, this can be seen as a special case of obstacle avoidance that just uses a different motor strategy. The random direction choice is important: always turning the same way would make the robot fail consistently in symmetric situations.