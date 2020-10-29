input = {}
input.mouse_buttons = {"m1", "m2", "m3", "m4", "m5", "wheel_up", "wheel_down"}
input.gamepad_buttons = {"fdown", "fup", "fleft", "fright", "dpdown", "dpup", "dpleft", "dpright", "start", "back", "guide", "leftstick", "rightstick", "rb", "lb"}
input.index_to_gamepad_button = {["a"] = "fdown", ["b"] = "fright", ["x"] = "fleft", ["y"] = "fup", ["back"] = "back", ["start"] = "start", ["guide"] = "guide", ["leftstick"] = "leftstick", ["rightstick"] = "rightstick", ["leftshoulder"] = "lb", ["rightshoulder"] = "rb", ["dpdown"] = "dpdown", ["dpup"] = "dpup", ["dpleft"] = "dpleft", ["dpright"] = "dpright",
}
input.index_to_gamepad_axis = {["leftx"] = "leftx", ["rightx"] = "rightx", ["lefty"] = "lefty", ["righty"] = "righty", ["triggerleft"] = "lt", ["triggerright"] = "rt"}
input.gamepad_axis = {}
input.joystick = love.joystick.getJoysticks()[1]
input.keyboard_state = {}
input.previous_keyboard_state = {}
input.mouse_state = {}
input.previous_mouse_state = {}
input.gamepad_state = {}
input.previous_gamepad_state = {}
input.actions = {}
input.textinput_buffer = ""


function input.update()
  for _, action in ipairs(input.actions) do
    input[action].pressed = false
    input[action].down = false
    input[action].released = false
  end

  for _, action in ipairs(input.actions) do
    for _, key in ipairs(input[action].keys) do
      if table.contains(input.mouse_buttons, key) then
        input[action].pressed = input[action].pressed or (input.mouse_state[key] and not input.previous_mouse_state[key])
        input[action].down = input[action].down or input.mouse_state[key]
        input[action].released = input[action].released or (not input.mouse_state[key] and  input.previous_mouse_state[key])
      elseif table.contains(input.gamepad_buttons, key) then
        input[action].pressed = input[action].pressed or (input.gamepad_state[key] and not input.previous_gamepad_state[key])
        input[action].down = input[action].down or input.gamepad_state[key]
        input[action].released = input[action].released or (not input.gamepad_state[key] and  input.previous_gamepad_state[key])
      else
        input[action].pressed = input[action].pressed or (input.keyboard_state[key] and not input.previous_keyboard_state[key])
        input[action].down = input[action].down or input.keyboard_state[key]
        input[action].released = input[action].released or (not input.keyboard_state[key] and input.previous_keyboard_state[key])
      end
    end
  end


  input.previous_mouse_state = table.copy(input.mouse_state)
  input.previous_gamepad_state = table.copy(input.gamepad_state)
  input.previous_keyboard_state = table.copy(input.keyboard_state)
  input.mouse_state.wheel_up = false
  input.mouse_state.wheel_down = false
end


function input.bind(action, keys)
  if not input[action] then input[action] = {} end
  if type(keys) == "string" then input[action].keys = {keys}
  elseif type(keys) == "table" then input[action].keys = keys end
  table.insert(input.actions, action)
end


function input.unbind(action)
  input[action] = nil
end


function input.axis(key)
  return input.gamepad_axis[key]
end


function input.textinput(text)
  input.textinput_buffer = input.textinput_buffer .. text
end


function input.get_and_clear_textinput_buffer()
  local buffer = input.textinput_buffer
  input.textinput_buffer = ""
  return buffer
end


-- Set direct input binds for every keyboard and mouse key
-- Mostly to be used if you want to skip the action system and refer to keys directly (i.e. for internal tools or menus that don't need their keys changed ever)
local keyboard_binds = {['a'] = {'a'}, ['b'] = {'b'}, ['c'] = {'c'}, ['d'] = {'d'}, ['e'] = {'e'}, ['f'] = {'f'}, ['g'] = {'g'}, ['h'] = {'h'}, ['i'] = {'i'}, ['j'] = {'j'}, ['k'] = {'k'}, ['l'] = {'l'}, ['m'] = {'m'}, ['n'] = {'n'}, ['o'] = {'o'}, ['p'] = {'p'}, ['q'] = {'q'}, ['r'] = {'r'}, ['s'] = {'s'}, ['t'] = {'t'}, ['u'] = {'u'}, ['v'] = {'v'}, ['w'] = {'w'}, ['x'] = {'x'}, ['y'] = {'y'}, ['z'] = {'z'}, ['0'] = {'0'}, ['1'] = {'1'}, ['2'] = {'2'}, ['3'] = {'3'}, ['4'] = {'4'}, ['5'] = {'5'}, ['6'] = {'6'}, ['7'] = {'7'}, ['8'] = {'8'}, ['9'] = {'9'}, ['space'] = {'space'}, ['!'] = {'!'}, ['"'] = {'"'}, ['#'] = {'#'}, ['$'] = {'$'}, ['&'] = {'&'}, ["'"] = {"'"}, ['('] = {'('}, [')'] = {')'}, ['*'] = {'*'}, ['+'] = {'+'}, [','] = {','}, ['-'] = {'-'}, ['.'] = {'.'}, ['/'] = {'/'}, [':'] = {':'}, [';'] = {';'}, ['kp0'] = {'kp0'}, ['kp1'] = {'kp1'}, ['kp2'] = {'kp2'}, ['kp3'] = {'kp3'}, ['kp4'] = {'kp4'}, ['kp5'] = {'kp5'}, ['kp6'] = {'kp6'}, ['kp7'] = {'kp7'}, ['kp8'] = {'kp8'}, ['kp9'] = {'kp9'}, ['kp.'] = {'kp.'}, ['kp,'] = {'kp,'}, ['kp/'] = {'kp/'}, ['kp*'] = {'kp*'}, ['kp-'] = {'kp-'}, ['kp+'] = {'kp+'}, ['kpenter'] = {'kpenter'}, ['kp='] = {'kp='}, ['up'] = {'up'}, ['down'] = {'down'}, ['right'] = {'right'}, ['left'] = {'left'}, ['home'] = {'home'}, ['pageup'] = {'pageup'}, ['pagedown'] = {'pagedown'}, ['insert'] = {'insert'}, ['backspace'] = {'backspace'}, ['tab'] = {'tab'}, ['clear'] = {'clear'}, ['return'] = {'return'}, ['delete'] = {'delete'}, ['f1'] = {'f1'}, ['f2'] = {'f2'}, ['f3'] = {'f3'}, ['f4'] = {'f4'}, ['f5'] = {'f5'}, ['f6'] = {'f6'}, ['f7'] = {'f7'}, ['f8'] = {'f8'}, ['f9'] = {'f9'}, ['f10'] = {'f10'}, ['f11'] = {'f11'}, ['f12'] = {'f12'}, ['f13'] = {'f13'}, ['f14'] = {'f14'}, ['f15'] = {'f15'}, ['f16'] = {'f16'}, ['f17'] = {'f17'}, ['f18'] = {'f18'}, ['numlock'] = {'numlock'}, ['capslock'] = {'capslock'}, ['scrolllock'] = {'scrolllock'}, ['rshift'] = {'rshift'}, ['lshift'] = {'lshift'}, ['rctrl'] = {'rctrl'}, ['lctrl'] = {'lctrl'}, ['ralt'] = {'ralt'}, ['lalt'] = {'lalt'}, ['rgui'] = {'rgui'}, ['lgui'] = {'lgui'}, ['mode'] = {'mode'}, ['escape'] = {'escape'}}
for k, v in pairs(keyboard_binds) do input.bind(k, v) end
input.bind('m1', {'m1'})
input.bind('m2', {'m2'})
input.bind('m3', {'m3'})
input.bind('m4', {'m4'})
input.bind('m5', {'m5'})
input.bind('wheel_up', {'wheel_up'})
input.bind('wheel_down', {'wheel_down'})
