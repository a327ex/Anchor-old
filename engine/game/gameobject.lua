-- The base GameObject class.  
-- Provides a lot of useful functionality if you need your objects to be box2d physical objects.
-- In the future I plan on expanding this such that it provides the same functions and they work even for objects that aren't box2d ones.
-- The general way of creating an object that implements these functions goes like this:
--[[
MyGameObject = Object:extend()
MyGameObject:implement(GameObject)

function MyGameObject:new(group, x, y, opts)
  self:new_game_object(group, x, y, opts)
end

function MyGameObject:update(dt)
  self:update_game_object(dt)
end

function MyGameObject:draw()

end
]]--

-- This simply implements the GameObject class as a mixin into your own class, giving it all these functions as well as the attributes set from new_game_object.
-- In general you'd create your own game object like this, for instance:
-- group = Group()
-- group:add_object(MyGameObject(group, 100, 100, {v = 100, r = math.pi/4})
-- And then this object would be automatically updated and drawn by the group (as long as you call the group's update and drawn functions, of course!)
-- One of the nice patterns I've found was having the x, y attributes passed in first and then a table of optional values that can be in any order.
-- So in the case above, the object would automatically have its .v attribute set to 100 and its .r attribute set to math.pi/4, on top of its x, y position.
--
-- You don't need to use objects that implement GameObject to add them to groups.
-- If you want your own objects to have their own functionalities completely unrelated to any of this then simply have that be the case and don't implement GameObject.
-- That would look something like this:
--[[
MyClass = Object:extend()

function MyClass:new()
  
end

function MyClass:update(dt)

end

function MyClass:draw()

end
]]--

-- And then adding an instance to a group:
-- group = Group()
-- group:add_object(MyClass())
-- If I don't need the object to have physics or movement functionality then I generally create my classes as shown right above (not implementing GameObject), otherwise as it was first shown.
local new_game_object = function(self, group, x, y, opts)
  self.group = group
  self.x, self.y = x, y
  self.r = 0
  self.sx, self.sy = 1, 1
  for k, v in pairs(opts or {}) do self[k] = v end
  self.id = random:uid()
  self.timer = Timer()
  self.group:add_object(self)
  return self
end


local game_object_methods = {}


game_object_methods.update_game_object = function(self, dt)
  self.timer:update(dt)

  if self.steerable and self.steering_enabled then
    local steering_force = self:calculate_steering_force(dt)
    local a = steering_force:div(self.mass)
    self.v:add(a:mul(dt))
    self.v:truncate(self.max_v)
    self:set_velocity(self.v.x, self.v.y)
    if self.v:length_squared() > 0.00001 then
      self.heading = self.v:clone():normalize()
      self.side = self.heading:perpendicular()
    end
    if steering_force:length_squared() < 10 then self.v:mul(self.damping*dt) end
  end

  self:update_position()

  if self.shape then
    if self.shape.vertices and self.body then
      self.shape.vertices = {self.body:getWorldPoints(self.fixture:getShape():getPoints())}
      self.shape:get_centroid()
    end
    self.shape.x, self.shape.y = self:get_position()

    if self.interact_with_mouse then
      local colliding_with_mouse = self.shape:is_colliding_with_points(self.group:get_mouse_position())
      if colliding_with_mouse and not self.colliding_with_mouse then
        self.colliding_with_mouse = true
        if self.on_mouse_enter then self:on_mouse_enter() end
      elseif not colliding_with_mouse and self.colliding_with_mouse then
        self.colliding_with_mouse = false
        if self.on_mouse_exit then self:on_mouse_exit() end
      end
      if self.colliding_with_mouse then
        if self.on_mouse_stay then self:on_mouse_stay() end
      end
    end
  end
end


-- Updates the .x, .y attributes of this object, useful to call before drawing something if you need its position as recent as position
-- self:update_position()
game_object_methods.update_position = function(self)
  if self.body then self.x, self.y = self.body:getPosition() end
  return self
end


-- Sets the object's position directly, avoid using if you need velocity/acceleration calculations to make sense and be accurate, as teleporting the object around messes up its physics
-- self:set_position(100, 100)
game_object_methods.set_position = function(self, x, y)
  if self.body then self.body:setPosition(x, y) end
  return self:update_position()
end


-- Returns the object's position as two values 
-- x, y = self:get_position()
game_object_methods.get_position = function(self)
  self:update_position()
  if self.body then return self.body:getPosition()
  else return self.x, self.y end
end


-- Sets the object as a bullet
-- Bullets will collide and generate proper collision responses regardless of their velocity, despite being more expensive to calculate
-- self:set_bullet(true)
game_object_methods.set_bullet = function(self, v)
  if self.body then self.body:setBullet(v) end
  return self
end


-- Sets the object to have fixed rotation
-- When box2d objects don't have fixed rotation, whenever they collide with other objects they will rotate around depending on where the collision happened
-- Setting this to true prevents that from happening, useful for every type of game where you don't need accurate physics responses in terms of the characters rotation
-- self:set_fixed_rotation(true)
game_object_methods.set_fixed_rotation = function(self, v)
  self.fixed_rotation = v
  if self.body then self.body:setFixedRotation(v) end
  return self
end


-- Sets the object's velocity
-- self:set_velocity(100, 100)
game_object_methods.set_velocity = function(self, vx, vy)
  if self.body then
    self.body:setLinearVelocity(vx, vy)
  else
    self.v.x = vx
    self.v.y = vy
  end
  return self
end


-- Returns the object's velocity as two values
-- vx, vy = self:get_velocity()
game_object_methods.get_velocity = function(self)
  if self.body then return self.body:getLinearVelocity()
  else return self.v.x, self.v.y end
end


-- Sets the object's damping
-- The higher this value, the more the object will resist movement and the faster it will stop moving after forces are applied to it
-- self:set_damping(10)
game_object_methods.set_damping = function(self, v)
  if self.body then
    self.body:setLinearDamping(v)
  else
    self.damping = v
  end
  return self
end


-- Sets the object's angular velocity
-- If set_fixed_rotation is set to true then this will do nothing
-- self:set_angular_velocity(math.pi/4)
game_object_methods.set_angular_velocity = function(self, v)
  if self.body then
    self.body:setAngularVelocity(v)
  else
    self.angular_v = v
  end
  return self
end


-- Sets the object's angular damping
-- The higher this value, the more the object will resist rotation and the faster it will stop rotating after angular forces are applied to it
-- self:set_angular_damping(10)
game_object_methods.set_angular_damping = function(self, v)
  if self.body then
    self.body:setAngularDamping(v)
  else
    self.angular_damping = v
  end
  return self
end


-- Returns the object's angle
-- r = self:get_angle()
game_object_methods.get_angle = function(self)
  if self.body then return self.body:getAngle()
  else return self.r end
end


-- Sets the object's angle
-- If set_fixed_rotation is set to true then this will do nothing
-- self:set_angle(math.pi/8)
game_object_methods.set_angle = function(self, v)
  self.r = v
  if self.body then self.body:setAngle(v) end
  return self
end


-- Sets the object's restitution
-- This is a value from 0 to 1 and the higher it is the more energy the object will conserve when bouncing off other objects
-- At 1, it will bounce perfectly and not lose any velocity
-- At 0, it will not bounce at all
-- self:set_restitution(0.75)
game_object_methods.set_restitution = function(self, v)
  if self.fixture then
    self.fixture:setRestitution(v)
  elseif self.fixtures then
    for _, fixture in ipairs(self.fixtures) do
      fixture:setRestitution(v)
    end
  end
  return self
end


-- Sets the object's friction
-- This is a value from 0 to infinity, but generally between 0 and 1, the higher it is the more friction there will be when this object slides with another
-- At 0 friction is turned off and the object will slide with no resistance
-- The friction calculation takes into account the friction of both objects sliding on one another, so if one object has friction set to 0 then it will treat the interaction as if there's no friction
-- self:set_friction(1)
game_object_methods.set_friction = function(self, v)
  if self.fixture then
    self.fixture:setFriction(v)
  elseif self.fixtures then
    for _, fixture in ipairs(self.fixtures) do
      fixture:setFriction(v)
    end
  end
  return self
end


-- Applies an instantaneous amount of force to the object
-- self:apply_impulse(100*math.cos(angle), 100*math.sin(angle))
game_object_methods.apply_impulse = function(self, fx, fy)
  self.body:applyLinearImpulse(fx, fy)
  return self
end


-- Applies a continuous amount of force to the object
-- self:apply_force(100*math.cos(angle), 100*math.sin(angle))
game_object_methods.apply_force = function(self, fx, fy)
  if self.body then
    self.body:applyForce(fx, fy)
  else
    self.a.x = self.a.x + fx
    self.a.y = self.a.y + fy
  end
  return self
end


-- Applies torque to the object
-- self:apply_torque(math.pi)
game_object_methods.apply_torque = function(self, t)
  self.body:applyTorque(t)
  return self
end


-- Sets the object's mass
-- self:set_mass(1000)
game_object_methods.set_mass = function(self, mass)
  self.body:setMass(mass)
  return self
end


-- Sets the object's gravity scale
-- This is a simple multiplier on the world's gravity, but applied only to this object
game_object_methods.set_gravity_scale = function(self, v)
  self.body:setGravityScale(v)
  return self
end



-- Moves this object towards another object
-- You can either do this by using the speed argument directly, or by using the max_time argument
-- max_time will override speed since it will make it so that the object reaches the target in a given time
-- self:move_towards_object(player, 40) -> moves towards the player with 40 speed
-- self:move_towards_object(player, nil, 2) -> moves towards the player with speed such that it would reach him in 2 seconds if he never moved
game_object_methods.move_towards_object = function(self, object, speed, max_time)
  if max_time then speed = self:distance_to_point(object.x, object.y)/max_time end
  local r = self:angle_to_point(object.x, object.y)
  self:set_velocity(speed*math.cos(r), speed*math.sin(r))
  return self
end


-- Same as move_towards_object except towards a point
-- self:move_towards_point(player.x, player.y, 40)
game_object_methods.move_towards_point = function(self, x, y, speed, max_time)
  if max_time then speed = self:distance_to_point(x, y)/max_time end
  local r = self:angle_to_point(x, y)
  self:set_velocity(speed*math.cos(r), speed*math.sin(r))
  return self
end


-- Same as move_towards_object and move_towards_point except towards the mouse
-- self:move_towards_mouse(nil, 1)
game_object_methods.move_towards_mouse = function(self, speed, max_time)
  if max_time then speed = self:distance_to_mouse()/max_time end
  local r = self:angle_to_mouse()
  self:set_velocity(speed*math.cos(r), speed*math.sin(r))
  return self
end


-- Moves the object along an angle, most useful for simple projectiles that don't need any complex movements
-- self:move_along_angle(100, math.pi/4)
game_object_methods.move_along_angle = function(self, speed, r)
  self:set_velocity(speed*math.cos(r), speed*math.sin(r))
  return self
end


-- Rotates the object towards another object using a rotational lerp, which is a value from 0 to 1
-- Higher values will rotate the object faster, lower values will make the turn have a smooth delay to it
-- self:rotate_towards_object(player, 0.2)
game_object_methods.rotate_towards_object = function(self, object, lerp_value)
  self:set_angle(math.lerp_angle(lerp_value, self:get_angle(), self:angle_to_point(object.x, object.y)))
  return self
end


-- Same as rotate_towards_object except towards a point
-- self:rotate_towards_point(player.x, player.y, 0.2)
game_object_methods.rotate_towards_point = function(self, x, y, lerp_value)
  self:set_angle(math.lerp_angle(lerp_value, self:get_angle(), self:angle_to_point(x, y)))
  return self
end


-- Same as rotate_towards_object and rotate_towards_point except towards the mouse
-- self:rotate_towards_mouse(0.2)
game_object_methods.rotate_towards_mouse = function(self, lerp_value)
  self:set_angle(math.lerp_angle(lerp_value, self:get_angle(), self:angle_to_mouse()))
  return self
end


-- Rotates the object towards its own velocity vector using a rotational lerp, which is a value from 0 to 1
-- Higher values will rotate the object faster, lower values will make the turn have a smooth delay to it
-- self:rotate_towards_velocity(0.2)
game_object_methods.rotate_towards_velocity = function(self, lerp_value)
  local vx, vy = self:get_velocity()
  self:set_angle(math.lerp_angle(lerp_value, self:get_angle(), self:angle_to_point(self.x + vx, self.y + vy)))
  return self
end


-- Same as accelerate_towards_object except towards a point
-- self:accelerate_towards_object(player.x, player.y, 100, 10, 2)
game_object_methods.accelerate_towards_point = function(self, x, y, max_speed, deceleration, turn_coefficient)
  local tx, ty = x - self.x, y - self.y
  local d = math.length(tx, ty)
  if d > 0 then
    local speed = d/((deceleration or 1)*0.08)
    speed = math.min(speed, max_speed)
    local current_vx, current_vy = speed*tx/d, speed*ty/d
    local vx, vy = self:get_velocity()
    self:apply_force((current_vx - vx)*(turn_coefficient or 1), (current_vy - vy)*(turn_coefficient or 1))
  end
  return self
end


-- Accelerates the object towards another object
-- Other than the object, the 3 arguments available are:
-- max_speed - the maximum speed the object can have in this acceleration
-- deceleration - how fast the object will decelerate once it gets closer to the target, higher values will make the deceleration more abrupt, do not make this value 0
-- turn_coefficient - how strong is the turning force for this object, higher values will make it turn faster
-- self:accelerate_towards_object(player, 100, 10, 2)
game_object_methods.accelerate_towards_object = function(self, object, max_speed, deceleration, turn_coefficient)
  return self:accelerate_towards_point(object.x, object.y, max_speed, deceleration, turn_coefficient)
end


-- Same as accelerate_towards_object and accelerate_towards_point but towards the mouse
-- self:accelerate_towards_mouse(100, 10, 2)
game_object_methods.accelerate_towards_mouse = function(self, max_speed, deceleration, turn_coefficient)
  local mx, my = self.group.camera:get_mouse_position()
  return self:accelerate_towards_point(mx, my, max_speed, deceleration, turn_coefficient)
end


-- Keeps this object separated from other objects of specific classes according to the radius passed in
-- What this function does is simply look at all nearby objects and apply forces to this object such that it remains separated from them
-- self:separate2(40, {Enemy}) -> when this is called every frame, this applies forces to this object to keep it separated from other Enemy instances by 40 units at all times
-- TODO: optimize this, remove Vector creation, use bucket/cell system in groups for neighbor queries, cache what can be cached
game_object_methods.separate2 = function(self, rs, class_avoid_list)
  local fx, fy = 0, 0
  local objects = table.flatten(table.foreachn(class_avoid_list, function(v) return self.group:get_objects_by_class(v) end), true)
  for _, object in ipairs(objects) do
    if object.id ~= self.id and math.distance(object.x, object.y, self.x, self.y) < 2*rs then
      local tx, ty = self.x - object.x, self.y - object.y
      local n = Vector(tx, ty):normalize()
      local l = n:length()
      fx = fx + rs*(n.x/l)
      fy = fy + rs*(n.y/l)
    end
  end
  self:apply_force(fx, fy)
  return self
end


-- Returns the angle from this object to a point
-- r = self:angle_to_point(player.x, player.y) -> angle from this object to the player
game_object_methods.angle_to_point = function(self, x, y)
  return math.atan2(y - self.y, x - self.x)
end


-- Sets the object as a steerable object.
-- The implementation of steering behaviors here mostly follows the one from chapter 3 of the book "Programming Game AI by Example"
-- https://github.com/wangchen/Programming-Game-AI-by-Example-src
-- self:set_as_steerable(100, 1000)
game_object_methods.set_as_steerable = function(self, max_v, max_f, max_turn_rate, turn_multiplier)
  self.steerable = true
  self.steering_enabled = true
  self.v = Vector()
  self.heading = Vector()
  self.side = Vector()
  self.mass = 1
  self.max_v = max_v or 100
  self.max_f = max_f or 2000
  self.max_turn_rate = max_turn_rate or 2*math.pi
  self.turn_multiplier = turn_multiplier or 2
  self.damping = 0.95*refresh_rate
  self.seek_f = Vector()
  self.flee_f = Vector()
  self.pursuit_f = Vector()
  self.evade_f = Vector()
  self.wander_f = Vector()
  local r = random:float(0, 2*math.pi)
  self.wander_target = Vector(40*math.cos(r), 40*math.sin(r))
  self.path_follow_f = Vector()
  self.separation_f = Vector()
  self.alignment_f = Vector()
  self.cohesion_f = Vector()
end


game_object_methods.calculate_steering_force = function(self, dt)
  local steering_force = Vector(0, 0)
  if self.seeking then steering_force:add(self.seek_f) end
  if self.fleeing then steering_force:add(self.flee_f) end
  if self.pursuing then steering_force:add(self.pursuit_f) end
  if self.evading then steering_force:add(self.evade_f) end
  if self.wandering then steering_force:add(self.wander_f) end
  if self.path_following then steering_force:add(self.path_follow_f) end
  if self.separating then steering_force:add(self.separation_f) end
  if self.aligning then steering_force:add(self.alignment_f) end
  if self.cohesing then steering_force:add(self.cohesion_f) end
  self.seeking = false
  self.fleeing = false
  self.pursuing = false
  self.evading = false
  self.wandering = false
  self.path_following = false
  self.separating = false
  self.aligning = false
  self.cohesing = false
  return steering_force:truncate(self.max_f)
end


-- Arrive steering behavior
-- Makes this object accelerate towards a destination, slowing down the closer it gets to it
-- deceleration - how fast the object will decelerate once it gets closer to the target, higher values will make the deceleration more abrupt, do not make this value 0
-- weight - how much the force of this behavior affects this object compared to others
-- self:seek_point(player.x, player.y)
game_object_methods.seek_point = function(self, x, y, deceleration, weight)
  self.seeking = true
  local tx, ty = x - self.x, y - self.y
  local d = math.length(tx, ty)
  if d > 0 then
    local v = d/((deceleration or 1)*0.08)
    v = math.min(v, self.max_v)
    local dvx, dvy = v*tx/d, v*ty/d
    self.seek_f:set((dvx - self.v.x)*self.turn_multiplier*(weight or 1), (dvy - self.v.y)*self.turn_multiplier*(weight or 1))
  else self.seek_f:set(0, 0) end
end


-- Same as self:seek_point but for objects instead.
-- self:seek_object(player)
game_object_methods.seek_object = function(self, object, deceleration, weight)
  return self:seek_point(object.x, object.y, deceleration, weight)
end


-- Same as self:seek_point and self:seek_object but for the mouse instead.
-- self:seek_mouse()
game_object_methods.seek_mouse = function(self, deceleration, weight)
  local mx, my = self.group.camera:get_mouse_position()
  return self:seek_point(mx, my, deceleration, weight)
end


-- Separation steering behavior
-- Keeps this object separated from other objects of specific classes according to the radius passed in
-- What this function does is simply look at all nearby objects and apply forces to this object such that it remains separated from them
-- self:separate(40, {Enemy}) -> when this is called every frame, this applies forces to this object to keep it separated from other Enemy instances by 40 units at all times
-- TODO: optimize this, use bucket/cell system in groups for neighbor queries, cache what can be cached
game_object_methods.separate = function(self, rs, class_avoid_list, weight)
  self.separating = true
  local fx, fy = 0, 0
  local objects = table.flatten(table.foreachn(class_avoid_list, function(v) return self.group:get_objects_by_class(v) end), true)
  for _, object in ipairs(objects) do
    if object.id ~= self.id and math.distance(object.x, object.y, self.x, self.y) < 2*rs then
      local tx, ty = self.x - object.x, self.y - object.y
      local nx, ny = math.normalize(tx, ty)
      local l = math.length(nx, ny)
      fx = fx + rs*(nx/l)
      fy = fy + rs*(ny/l)
    end
  end
  self.separation_f:set(fx*(weight or 1), fy*(weight or 1))
end


-- Wander steering behavior
-- Makes the object move in a jittery manner, adding some randomness to its movement while keeping the overall direction
-- What this function does is project a circle in front of the entity and then choose a point randomly inside that circle for the entity to move towards and it does that every frame
-- rs - the radius of the circle
-- distance - the distance of the circle from this object, the further away the smoother the changes to movement will be
-- jitter - the amount of jitter to the movement, the higher it is the more abrupt the changes will be
-- self:wander(dt, 50, 100, 20)
game_object_methods.wander = function(self, rs, distance, jitter, weight)
  self.wandering = true
  self.wander_target:add(random:float(-1, 1)*(jitter or 20), random:float(-1, 1)*(jitter or 20))
  self.wander_target:normalize()
  self.wander_target:mul(rs or 40)
  local target_local = self.wander_target:clone():add(distance or 40, 0)
  local target_world = point_to_world_space(target_local, self.heading, self.side, Vector(self.x, self.y))
  self.wander_f:set((target_world.x - self.x)*(weight or 1), (target_world.y - self.y)*(weight or 1))
end


-- Returns the angle from a point to this object
-- r = self:angle_from_point(player.x, player.y) -> angle from the player to this object
game_object_methods.angle_from_point = function(self, x, y)
  return math.atan2(self.y - y, self.x - x)
end


-- Returns the angle from this object to another object
-- r = self:angle_to_object(player) -> angle from this object to the player
game_object_methods.angle_to_object = function(self, object)
  return self:angle_to_point(object.x, object.y)
end


-- Returns the angle from an object to this object
-- r = self:angle_from_object(player) -> angle from the player to this object
game_object_methods.angle_from_object = function(self, object)
  return self:angle_from_point(object.x, object.y)
end


-- Returns the angle from this object to the mouse
-- r = self:angle_to_mouse()
game_object_methods.angle_to_mouse = function(self)
  local mx, my = self.group.camera:get_mouse_position()
  return math.atan2(my - self.y, mx - self.x)
end


-- Returns the distance from this object to a point
-- d = self:distance_to_point(player.x, player.y)
game_object_methods.distance_to_point = function(self, x, y)
  return math.distance(self.x, self.y, x, y)
end


-- Returns the distance from an object to this object
-- d = self:distance_to_object(player)
game_object_methods.distance_to_object = function(self, object)
  return math.distance(self.x, self.y, object.x, object.y)
end


-- Returns the distance from this object to the mouse
-- d = self:angle_to_mouse()
game_object_methods.distance_to_mouse = function(self)
  local mx, my = self.group.camera:get_mouse_position()
  return math.distance(self.x, self.y, mx, my)
end


-- Returns true if this GameObject is colliding with the given point.
-- colliding = self:is_colliding_with_point(x, y)
game_object_methods.is_colliding_with_point = function(self, x, y)
  return self:is_colliding_with_point(x, y)
end


-- Returns true if this GameObject is colliding with the mouse.
-- colliding = self:is_colliding_with_mouse()
game_object_methods.is_colliding_with_mouse = function(self)
  return self:is_colliding_with_point(self.group.camera:get_mouse_position())
end


-- Returns true if this GameObject is colliding with another GameObject.
-- Both must be physics objects set with one of the set_as_shape functions.
-- colliding = self:is_colliding_with_object(other)
game_object_methods.is_colliding_with_object = function(self, object)
  return self:is_colliding_with_shape(object.shape)
end


-- Returns true if this GameObject is colliding with the given shape.
-- colliding = self:is_colliding_with_shape(shape)
game_object_methods.is_colliding_with_shape = function(self, shape)
  return self.shape:is_colliding_with_shape(shape)
end


-- Exactly the same as group:get_objects_in_shape, except additionally it automatically removes this object from the results.
-- self:get_objects_in_shape(Circle(self.x, self.y, 100), {Enemy1, Enemy2, Enemy3}) -> all objects of class Enemy1, Enemy2 and Enemy3 in a circle of radius 100 around this object
game_object_methods.get_objects_in_shape = function(self, shape, object_types)
  return table.select(self.group:get_objects_in_shape(shape, object_types), function(v) return v.id ~= self.id end)
end


-- Returns the closest object to this object in the given shape, optionally excluding objects in the exclude list passed in.
-- self:get_closest_object_in_shape(Circle(self.x, self.y, 100), {Enemy1, Enemy2, Enemy3}) -> closest object of class Enemy1, Enemy2 or Enemy3 in a circle of radius 100 around this object
-- self:get_closest_object_in_shape(Circle(self.x, self.y, 100), {Enemy1, Enemy2, Enemy3}, {object_1, object_2}) -> same as above except excluding object instances object_1 and object_2
game_object_methods.get_closest_object_in_shape = function(self, shape, object_types, exclude_list)
  local objects = self:get_objects_in_shape(shape, object_types)
  local min_d, min_i = 1000000, 0
  local exclude_list = exclude_list or {}
  for i, object in ipairs(objects) do
    if not table.any(exclude_list, function(v) return v.id == object.id end) then
      local d = math.distance(self.x, self.y, object.x, object.y)
      if d < min_d then
        min_d = d
        min_i = i
      end
    end
  end
  if i ~= 0 then return objects[min_i] end
end


-- Returns a random object in the given shape, excluding this object and also optionally excluding objects in the exclude list passed in.
-- self:get_random_object_in_shape(Circle(self.x, self.y, 100), {Enemy1, Enemy2, Enemy3}) -> random object of class Enemy1, Enemy2 or Enemy3 in a circle of radius 100 around this object
-- self:get_random_object_in_shape(Circle(self.x, self.y, 100), {Enemy1, Enemy2, Enemy3}, {object_1, object_2}) -> same as above except excluding object instances object_1 and object_2
game_object_methods.get_random_object_in_shape = function(self, shape, object_types, exclude_list)
  local objects = self:get_objects_in_shape(shape, object_types)
  local exclude_list = exclude_list or {}
  local random_object = random:table(objects)
  local tries = 0
  if random_object then
    while table.any(exclude_list, function(v) return v.id == random_object.id end) and tries < 20 do
      random_object = random:table(objects)
      tries = tries + 1
    end
  end
  return random_object
end


-- Sets this object as a physics rectangle.
-- Its body_type can be either 'static', 'dynamic' or 'kinematic' (see box2d for more info) and its tag has to have been created in group:set_as_physics_world.
-- Its .shape variable is set to a Rectangle instance and this instance is updated to be in sync with the physics body every frame.
game_object_methods.set_as_rectangle = function(self, w, h, body_type, tag)
  self.tag = tag
  self.shape = Rectangle(self.x, self.y, w, h)
  self.body = love.physics.newBody(self.group.world, self.x, self.y, body_type or "dynamic")
  local shape = love.physics.newRectangleShape(self.shape.w, self.shape.h)
  self.fixture = love.physics.newFixture(self.body, shape)
  self.fixture:setUserData(self.id)
  self.fixture:setCategory(self.group.collision_tags[tag].category)
  self.fixture:setMask(unpack(self.group.collision_tags[tag].masks))
  if #self.group.trigger_tags[tag].triggers > 0 then
    self.sensor = love.physics.newFixture(self.body, shape)
    self.sensor:setUserData(self.id)
    self.sensor:setSensor(true)
  end
  return self
end


-- Sets this object as a physics line.
-- Its body_type can be either 'static', 'dynamic' or 'kinematic' (see box2d for more info) and its tag has to have been created in group:set_as_physics_world.
-- Its .shape variable is set to a Line instance and this instance is updated to be in sync with the physics body every frame.
game_object_methods.set_as_line = function(self, x1, y1, x2, y2, body_type, tag)
  self.tag = tag
  self.shape = Line(x1, y1, x2, y2)
  self.body = love.physics.newBody(self.group.world, 0, 0, body_type or "dynamic")
  local shape = love.physics.newEdgeShape(self.shape.x1, self.shape.y1, self.shape.x2, self.shape.y2)
  self.fixture = love.physics.newFixture(self.body, shape)
  self.fixture:setUserData(self.id)
  self.fixture:setCategory(self.group.collision_tags[tag].category)
  self.fixture:setMask(unpack(self.group.collision_tags[tag].masks))
  if #self.group.trigger_tags[tag].triggers > 0 then
    self.sensor = love.physics.newFixture(self.body, shape)
    self.sensor:setUserData(self.id)
    self.sensor:setSensor(true)
  end
  return self
end


-- Sets this object as a physics chain (a collection of edges)
-- Its body_type can be either 'static', 'dynamic' or 'kinematic' (see box2d for more info) and its tag has to have been created in group:set_as_physics_world.
-- If loop is set to true, then the collection of edges will be closed, forming a polygon. Otherwise it will be open.
-- Its .shape variable is set to a Chain instance and this instance is updated to be in sync with the physics body every frame.
game_object_methods.set_as_chain = function(self, loop, vertices, body_type, tag)
  self.tag = tag
  self.shape = Chain(loop, vertices)
  self.body = love.physics.newBody(self.group.world, 0, 0, body_type or "dynamic")
  local shape = love.physics.newChainShape(self.shape.loop, self.shape.vertices)
  self.fixture = love.physics.newFixture(self.body, shape)
  self.fixture:setUserData(self.id)
  self.fixture:setCategory(self.group.collision_tags[tag].category)
  self.fixture:setMask(unpack(self.group.collision_tags[tag].masks))
  if #self.group.trigger_tags[tag].triggers > 0 then
    self.sensor = love.physics.newFixture(self.body, shape)
    self.sensor:setUserData(self.id)
    self.sensor:setSensor(true)
  end
  return self
end


-- Sets this object as a physics polygon.
-- Its body_type can be either 'static', 'dynamic' or 'kinematic' (see box2d for more info) and its tag has to have been created in group:set_as_physics_world.
-- Its .shape variable is set to a Polygon instance and this instance is updated to be in sync with the physics body every frame.
game_object_methods.set_as_polygon = function(self, vertices, body_type, tag)
  self.tag = tag
  self.shape = Polygon(vertices)
  self.body = love.physics.newBody(self.group.world, 0, 0, body_type or "dynamic")
  self.body:setPosition(self.x, self.y)
  local shape = love.physics.newPolygonShape(self.shape.vertices)
  self.fixture = love.physics.newFixture(self.body, shape)
  self.fixture:setUserData(self.id)
  self.fixture:setCategory(self.group.collision_tags[tag].category)
  self.fixture:setMask(unpack(self.group.collision_tags[tag].masks))
  if #self.group.trigger_tags[tag].triggers > 0 then
    self.sensor = love.physics.newFixture(self.body, shape)
    self.sensor:setUserData(self.id)
    self.sensor:setSensor(true)
  end
  return self
end


-- Sets this object as a physics circle.
-- Its body_type can be either 'static', 'dynamic' or 'kinematic' (see box2d for more info) and its tag has to have been created in group:set_as_physics_world.
-- Its .shape variable is set to a Circle instance and this instance is updated to be in sync with the physics body every frame.
game_object_methods.set_as_circle = function(self, rs, body_type, tag)
  self.tag = tag
  self.shape = Circle(self.x, self.y, rs)
  self.body = love.physics.newBody(self.group.world, self.x, self.y, body_type or "dynamic")
  local shape = love.physics.newCircleShape(self.shape.rs)
  self.fixture = love.physics.newFixture(self.body, shape)
  self.fixture:setUserData(self.id)
  self.fixture:setCategory(self.group.collision_tags[tag].category)
  self.fixture:setMask(unpack(self.group.collision_tags[tag].masks))
  if #self.group.trigger_tags[tag].triggers > 0 then
    self.sensor = love.physics.newFixture(self.body, shape)
    self.sensor:setUserData(self.id)
    self.sensor:setSensor(true)
  end
  return self
end


-- Sets this object as a physics triangle.
-- Its body_type can be either 'static', 'dynamic' or 'kinematic' (see box2d for more info) and its tag has to have been created in group:set_as_physics_world.
-- Its .shape variable is set to a Triangle instance and this instance is updated to be in sync with the physics body every frame.
game_object_methods.set_as_triangle = function(self, w, h, body_type, tag)
  self.tag = tag
  self.shape = Triangle(self.x, self.y, w, h)
  self.body = love.physics.newBody(self.group.world, 0, 0, body_type or "dynamic")
  self.body:setPosition(self.x, self.y)
  local x1, y1 = h/2, 0
  local x2, y2 = -h/2, -w/2
  local x3, y3 = -h/2, w/2
  local shape = love.physics.newPolygonShape({x1, y1, x2, y2, x3, y3})
  self.fixture = love.physics.newFixture(self.body, shape)
  self.fixture:setUserData(self.id)
  self.fixture:setCategory(self.group.collision_tags[tag].category)
  self.fixture:setMask(unpack(self.group.collision_tags[tag].masks))
  if #self.group.trigger_tags[tag].triggers > 0 then
    self.sensor = love.physics.newFixture(self.body, shape)
    self.sensor:setUserData(self.id)
    self.sensor:setSensor(true)
  end
  return self
end


game_object_methods.destroy = function(self)
  if self.body then
    if self.fixtures then for _, fixture in ipairs(self.fixtures) do fixture:destroy() end end
    if self.sensors then for _, sensor in ipairs(self.sensors) do sensor:destroy() end end
    if self.sensor then self.sensor:destroy(); self.sensor = nil end
    self.fixture:destroy()
    self.body:destroy()
    self.fixture, self.body = nil, nil
    if self.fixtures then self.fixtures = nil end
    if self.sensors then self.sensors = nil end
  end
end


game_object_methods.draw_game_object = function(self, color, line_width)
  if graphics.debug_draw then
    if self.shape then self.shape:draw(color, line_width or 4) end
  end
end


if moonscript then
  local _class_0
  local _base_0 = { }
  for k, v in pairs(game_object_methods) do _base_0[k] = v end
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = new_game_object,
    __base = _base_0,
    __name = "GameObject"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  GameObject = _class_0

else
  GameObject = Object:extend()
  GameObject.new_game_object = new_game_object
  for k, v in pairs(game_object_methods) do GameObject[k] = v end
end
