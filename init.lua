-- Hammerspoon config.

-- https://github.com/rxi/json.lua
json = require "json"

GETPR_EXECUTABLE = hs.configdir .. "/github_getprs.py"

EXTERNAL_LAYOUT = "British – PC"
INTERNAL_LAYOUT = "British"
KEYBOARD_NAME = 'USB Receiver'
KEYBOARD_VENDOR = 'Logitech'


-- Watch for external keyboard added/removed and set keyboard layout accordingly.
function maybeChangeLayout(devicetable)

  -- Debugging
  -- print('eventType ' .. tostring(devicetable['eventType']))
  -- print('productName ' .. tostring(devicetable['productName']))
  -- print('vendorName ' .. tostring(devicetable['vendorName']))
  -- print('vendorID ' .. tostring(devicetable['vendorID']))
  -- print('productID ' .. tostring(devicetable['productID']))
  
  if devicetable['eventType'] == 'added' 
    and devicetable['productName'] == KEYBOARD_NAME
    and devicetable['vendorName'] == KEYBOARD_VENDOR then
    print('External keyboard added, setting layout to ' .. EXTERNAL_LAYOUT)
    hs.keycodes.setLayout(EXTERNAL_LAYOUT)

  elseif devicetable['eventType'] == 'removed' 
    and devicetable['productName'] == KEYBOARD_NAME
    and devicetable['vendorName'] == KEYBOARD_VENDOR then
      print('External keyboard removed, setting layout to ' .. INTERNAL_LAYOUT)
    hs.keycodes.setLayout(INTERNAL_LAYOUT)
  end

end
watcher = hs.usb.watcher.new(maybeChangeLayout):start()


-- Add menubar with list of my open PRs and PRs requiring my review.
function runGetPRs()
  task = hs.task.new(GETPR_EXECUTABLE, setMenubar) 
  task:start()
end

function setMenubar(task, stdOut, stdErr)
  -- print(task)
  print('rungetprs returned:' .. stdOut)
  -- print(stdErr)

  data = json.decode(stdOut)
  any_requires_attention = false
  for index, value in next, data do
    data[index]['fn'] = function() hs.execute("open " .. value['url']) end
    any_requires_attention = any_requires_attention or value['requires_attention'] == "True"
  end
    
  numItems = #data
  title = any_requires_attention and "🔴" or "✅"
  title =  title .. numItems
  menubar:setMenu(data)
  menubar:setTitle(title)
end

menubar = hs.menubar.new()
menubar:setClickCallback(runGetPRs)
runGetPRs()

-- store timer in global variable to avoid gc
-- https://github.com/Hammerspoon/hammerspoon/issues/1942
myTimer = hs.timer.new(60, runGetPRs)
myTimer:start()


-- Spectacle like keybindings.
-- https://github.com/scottwhudson/Lunette
lunette = hs.spoons.use("Lunette")
customBindings = {
  leftHalf = {
    {{"cmd", "alt"}, "left"},
  },
  rightHalf = {
    {{"cmd", "alt"}, "right"},
  },
  topHalf = {},
  bottomHalf = {
    {{"cmd", "alt"}, "down"},
  },
  -- Conflicts with Google docs shortcuts
  -- topLeft = {{{"cmd", "alt"}, "7"}},
  -- topRight = {{{"cmd", "alt"}, "9"}},
  -- bottomLeft = {{{"cmd", "alt"}, "1"}},
  -- bottomRight = {{{"cmd", "alt"}, "3"}},
  fullScreen = {
    {{"cmd", "alt"}, "up"},
  },
  center = {},
  nextThird = {},
  prevThird = {},
  enlarge = {},
  shrink = {
  },
  nextDisplay = {
    {{"ctrl", "alt", "cmd"}, "Right"},
  },
  prevDisplay = {
    {{"ctrl", "alt", "cmd"}, "Left"},
  },
  undo = {},
  redo = {},
}
spoon.Lunette:bindHotkeys(customBindings)

-- UNUSED DEBUG STUFF


-- spoonInstall = hs.loadSpoon("SpoonInstall")


-- spoonInstall:andUse(
--   "USBDeviceActions",
--   {
--     config = {
--       devices = {
--         ScanSnapiX500EE            = { apps = { "ScanSnap Manager Evernote Edition" } },
--         Planck                     = { fn = toggleKeyboardLayout },
--         ["Corne Keyboard (crkbd)"] = { fn = toggleKeyboardLayout }
--       }
--     },
--     start = true
--   }
-- )

-- for k,v in pairs(_G) do
--   print("Global key", k, "value", v)
-- end



-- hs.hotkey.bind({"cmd", "alt", "ctrl"}, "W", function()
--   hs.alert.show("Hello World!")
-- end)



-- function toggleKeyboardLayout(x)
--   if x then
--     hs.keycodes.setLayout("British")
--   else
--     hs.keycodes.setLayout("British – PC")
--   end
-- end

-- hs.loadSpoon("USBDeviceActions")
-- print("cyp")
-- print(spoon.USBDeviceActions)
-- print()

-- function dump(o)
--   if type(o) == 'table' then
--      local s = '{ '
--      for k,v in pairs(o) do
--         if type(k) ~= 'number' then k = '"'..k..'"' end
--         s = s .. '['..k..'] = ' .. dump(v) .. ','
--      end
--      return s .. '} '
--   else
--      return tostring(o)
--   end
-- end

-- for key,value in pairs(spoon.USBDeviceActions) do
--   print("found member " .. key);
-- end
-- print("listing devices")
-- print(dump(hs.usb.attachedDevices()))
 
-- print("done listing devices")


-- menubar = hs.menubar.new(true, 'testmenubar')
-- menubar:setTitle('text')
-- menubar:setIcon('/Users/x/Desktop/SFImages/im-s-l16009.jpeg')
-- menubar:returnToMenuBar()
