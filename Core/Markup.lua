-- Section text to display strings: finds URLs and References and renders
-- them with the game's colour and hyperlink codes. Pure Lua.
local addonName, ns = ...

local Markup = {}
ns.Markup = Markup

local URL_COLOUR = "ff4fb8ff"
local REF_COLOUR = "ff71d5ff"
local URL_LINK = "fieldguideurl"
local REF_LINK = "fieldguideref"
local KINDS = { spell = true, item = true, talent = true }

local URL_PATTERN = "https?://[^%s]+"
-- "[" then a first character that is neither space nor "]", up to "]".
local REF_PATTERN = "%[[^%s%]][^%]]*%]"

local function push(runs, kind, text, extra)
  if text == "" then return end
  local run = extra or {}
  run.kind, run.text = kind, text
  runs[#runs + 1] = run
end

-- "spell:30451:Arcane Blast", "item:Lesser Magic Wand" or "Arcane Blast".
local function parseRef(inner)
  local kind, rest = inner:match("^(%a+):(.+)$")
  if not (kind and KINDS[kind:lower()]) then return { name = inner } end
  local id, name = rest:match("^(%d+):(.+)$")
  return { refKind = kind:lower(), id = id and tonumber(id), name = name or rest }
end

-- Returns runs: { kind = "text" | "url" | "ref", text = ... }; references
-- also carry refKind (nil, "spell", "item", "talent"), id and name.
function Markup.Tokenize(line)
  -- `literal` spans: shown as written, nothing inside is a link.
  local ls, le = line:find("`[^`]+`")
  if ls then
    local runs = Markup.Tokenize(line:sub(1, ls - 1))
    push(runs, "text", line:sub(ls + 1, le - 1))
    for _, run in ipairs(Markup.Tokenize(line:sub(le + 1))) do runs[#runs + 1] = run end
    return runs
  end
  local runs, pos = {}, 1
  while pos <= #line do
    local us, ue = line:find(URL_PATTERN, pos)
    local rs, re = line:find(REF_PATTERN, pos)
    if not us and not rs then break end
    if us and (not rs or us < rs) then
      local trimmed = line:sub(us, ue):gsub("[%.,;:!%?%)%]]+$", "")
      push(runs, "text", line:sub(pos, us - 1))
      push(runs, "url", trimmed)
      pos = us + #trimmed
    else
      local ref = parseRef(line:sub(rs + 1, re - 1))
      push(runs, "text", line:sub(pos, rs - 1))
      push(runs, "ref", ref.name, ref)
      pos = re + 1
    end
  end
  push(runs, "text", line:sub(pos))
  return runs
end

local function escape(text) return (text:gsub("|", "||")) end

function Markup.Render(line)
  local out = {}
  for _, run in ipairs(Markup.Tokenize(line)) do
    if run.kind == "url" then
      out[#out + 1] = ("|c%s|H%s:%s|h%s|h|r"):format(URL_COLOUR, URL_LINK, run.text, escape(run.text))
    elseif run.kind == "ref" then
      local name = escape(run.name)
      out[#out + 1] = ("|c%s|H%s:%s:%s:%s|h%s|h|r"):format(REF_COLOUR, REF_LINK,
        run.refKind or "", run.id or "", name, name)
    else
      out[#out + 1] = escape(run.text)
    end
  end
  return table.concat(out)
end

-- The URL carried by one of our hyperlinks, or nil for any other link.
function Markup.LinkURL(link)
  return link and link:match("^" .. URL_LINK .. ":(.+)$")
end

-- The reference carried by one of our hyperlinks: { refKind, id, name }, or nil.
function Markup.LinkRef(link)
  local kind, id, name = (link or ""):match("^" .. REF_LINK .. ":(%a*):(%d*):(.+)$")
  if not name then return nil end
  return { refKind = kind ~= "" and kind or nil, id = tonumber(id), name = (name:gsub("||", "|")) }
end
