-- Validates a Guide Import with the addon's own parser, outside the game.
--   luajit tools/validate.lua guides/<file>.guide.txt     (from the repo root)
-- Prints a summary, or each error with its line; exits 1 on errors.
local path = arg[1]
if not path then
  io.stderr:write("usage: luajit tools/validate.lua <file.guide.txt>\n")
  os.exit(2)
end

local ns = {}
for _, file in ipairs({ "Locales/enUS.lua", "Core/LevelingPath.lua", "Core/ImportParser.lua", "Core/Markup.lua" }) do
  assert(loadfile(file))("FieldGuide", ns)
end

local file = assert(io.open(path, "rb"))
local text = file:read("*a")
file:close()

local guide, errors = ns.ImportParser.Parse(text)
if not guide then
  for _, err in ipairs(errors) do print(("%s:%d: %s"):format(path, err.line, err.message)) end
  os.exit(1)
end

local steps, parts, refs = 0, 0, 0
local titles = {}
for _, section in ipairs(guide.sections) do
  titles[#titles + 1] = section.title
  if section.kind == "talents" then steps = #section.steps end
  if section.kind == "rotation" then parts = #section.parts end
  local lines = section.lines
  for _, line in ipairs(lines) do
    for _, run in ipairs(ns.Markup.Tokenize(line)) do
      if run.kind == "ref" then refs = refs + 1 end
    end
  end
end
print(("OK  %s - %s (%s)"):format(guide.title, guide.variant, guide.class))
print(("    %d sections: %s"):format(#guide.sections, table.concat(titles, ", ")))
print(("    %d talent steps, %d rotation parts, %d references, %d bytes"):format(steps, parts, refs, #text))
