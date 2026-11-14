-- Section text to display strings: finds URLs (and later References) and
-- renders them with the game's colour and hyperlink codes. Pure Lua.
local addonName, ns = ...

local Markup = {}
ns.Markup = Markup

local URL_COLOUR = "ff4fb8ff"
local LINK_TYPE = "fieldguideurl"

local function push(runs, kind, text, extra)
  if text == "" then return end
  local run = extra or {}
  run.kind, run.text = kind, text
  runs[#runs + 1] = run
end

-- Returns runs: { kind = "text" | "url", text = ... }.
function Markup.Tokenize(line)
  local runs, pos = {}, 1
  while pos <= #line do
    local s, e = line:find("https?://[^%s]+", pos)
    if not s then break end
    local url = line:sub(s, e)
    local trimmed = url:gsub("[%.,;:!%?%)%]]+$", "")
    push(runs, "text", line:sub(pos, s - 1))
    push(runs, "url", trimmed)
    pos = s + #trimmed
  end
  push(runs, "text", line:sub(pos))
  return runs
end

local function escape(text) return (text:gsub("|", "||")) end

function Markup.Render(line)
  local out = {}
  for _, run in ipairs(Markup.Tokenize(line)) do
    if run.kind == "url" then
      out[#out + 1] = ("|c%s|H%s:%s|h%s|h|r"):format(URL_COLOUR, LINK_TYPE, run.text, escape(run.text))
    else
      out[#out + 1] = escape(run.text)
    end
  end
  return table.concat(out)
end

-- The URL carried by one of our hyperlinks, or nil for any other link.
function Markup.LinkURL(link)
  return link and link:match("^" .. LINK_TYPE .. ":(.+)$")
end
