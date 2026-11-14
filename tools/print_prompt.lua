-- Writes the AI prompt to AI_PROMPT.txt (run from the repo root after
-- changing Core/AIPrompt.lua):  luajit tools/print_prompt.lua
local ns = {}
assert(loadfile("Core/AIPrompt.lua"))("FieldGuide", ns)
local file = assert(io.open("AI_PROMPT.txt", "wb"))
file:write(ns.AIPrompt.TEXT)
file:close()
print(("AI_PROMPT.txt written, %d characters"):format(#ns.AIPrompt.TEXT))
