local path = ...
if not path:find("init") then
  binser = require(path .. ".binser")
  mlib = require(path .. ".mlib")
  clipper = require(path .. ".clipper")
  ripple = require(path .. ".ripple")
end
