-- Unit tests for the pure Core files, outside the game.
--   luajit tests/run.lua   (from the repo root)
local ADDON = "FieldGuide"
local ns = {}
for _, file in ipairs({ "Locales/enUS.lua", "Core/ImportParser.lua", "Core/Library.lua", "Core/ImportReport.lua", "Core/Markup.lua", "Core/Rotation.lua", "Core/Display.lua" }) do
  assert(loadfile(file))(ADDON, ns)
end

local passed, failed = 0, 0
local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then passed = passed + 1 else
    failed = failed + 1
    print("FAIL  " .. name .. "\n      " .. tostring(err))
  end
end
local function eq(actual, expected, what)
  if actual ~= expected then
    error((what or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
  end
end

for _, file in ipairs({ "tests/importparser_test.lua", "tests/library_test.lua", "tests/importreport_test.lua", "tests/markup_test.lua", "tests/rotation_test.lua", "tests/display_test.lua" }) do
  assert(loadfile(file))(ns, test, eq)
end

print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
