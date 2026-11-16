--[[
infoblocks.lua -- Quarto filter: the JECS Quarto layout classes -> infoblocks
(Beamer). Does nothing for any other format, so reveal.js output is untouched.

Use in a deck's YAML:
  filters: [<path to>/infoblocks.lua]
  format:
    beamer:
      include-in-header: <preamble that loads infoblocks>
      template-partials: [<path to>/before-body.tex]   # \titleframe

Mapping (Quarto markdown -> LaTeX)
  ::: {.cards style="--cols:N"}  -> columns, N per row, cards level per row
  ::: {.card .red|.teal|.plain}  -> infocard (title from [..]{.card-title},
                                    icon from a []{.ic .bi .bi-x} span)
  ::: {.tiles style="--cols:N"}  -> \stattile in columns (N=1: stacked)
  ::: tile                       -> \stattile{icon}{.num}{.lbl ...}
  ::: takeaway                   -> takeaway bar
  ::: cite                       -> \ftnote{...} (JECS / NIES themes)
  ::: center                     -> center environment
  ::: iline                      -> paragraph with the icon inline
  ::: iconrow / .timeline        -> row of icon + label boxes
  ::: chain                      -> tiles with arrows between
  ::: factors                    -> chips -> arrow -> navy box
  ::: units / .compare / .steps  -> tabular
  ::: org                        -> 3-column grid of cards and arrows
  ::: photos / booklet           -> images in a row / image beside text
  ::: legend                     -> dropped (it explains HTML-only colours)
  []{.ic .bi .bi-x}              -> \iconcircle / \softicon (Font Awesome name)
  []{.bi .bi-x}                  -> \faIcon
  [..]{.chip}                    -> \ibchip
  paragraph of [..]{.stat}       -> \stat
  .num .lbl .quiet .ref .fig-title .lead ... -> font size / colour
  Image width/height in px       -> mm (1600 px slide = 160 mm Beamer slide)

Anything else passes through as plain content. For a slide that needs its
own Beamer layout, use Quarto's
  ::: {.content-visible when-format="beamer"} ... :::
  ::: {.content-visible unless-format="beamer"} ... :::
]]

if not (quarto and quarto.doc.is_format("beamer")) then
  return {}
end

-- Bootstrap Icons (Quarto decks) -> Font Awesome 7 Free (fontawesome7).
local ICONS = {
  ["activity"] = "wave-square", ["arrow-left-right"] = "arrows-left-right",
  ["arrow-right"] = "arrow-right", ["backpack"] = "school",
  ["balloon-heart"] = "baby", ["bank"] = "building-columns", ["book"] = "book",
  ["buildings"] = "city", ["bullseye"] = "bullseye", ["calendar3"] = "calendar",
  ["clipboard2-check"] = "clipboard-check", ["cup-hot"] = "mug-hot",
  ["dash-circle"] = "circle-minus", ["diagram-3"] = "sitemap",
  ["dice-5"] = "dice-five", ["droplet-fill"] = "droplet",
  ["droplet-half"] = "droplet", ["egg-fried"] = "egg",
  ["file-medical"] = "file-medical", ["fingerprint"] = "dna",
  ["flag"] = "flag", ["geo-alt"] = "location-dot", ["globe2"] = "earth-asia",
  ["hand-thumbs-up"] = "thumbs-up", ["heart-pulse"] = "heart-pulse",
  ["hospital"] = "hospital", ["hospital-fill"] = "house-medical",
  ["house"] = "house", ["house-heart"] = "house-chimney",
  ["journal-text"] = "file-lines", ["journals"] = "book", ["laptop"] = "laptop",
  ["lightbulb"] = "brain", ["lungs"] = "lungs", ["megaphone"] = "bullhorn",
  ["pencil-square"] = "pen-to-square", ["people"] = "people-group",
  ["people-fill"] = "users", ["person-check"] = "user-check",
  ["person-fill"] = "user", ["person-hearts"] = "person-pregnant",
  ["plus-circle"] = "circle-plus", ["safe2"] = "vault",
  ["search"] = "magnifying-glass", ["share"] = "share-nodes",
  ["signpost-split"] = "signs-post", ["tree"] = "tree", ["wind"] = "wind",
}
local FALLBACK_ICON = "circle"

-- ---------------------------------------------------------------- helpers
local function RI(s) return pandoc.RawInline("latex", s) end
local function RB(s) return pandoc.RawBlock("latex", s) end

local function has(el, c) return el.classes ~= nil and el.classes:includes(c) end

local function accent_of(el, default)
  if has(el, "red") or has(el, "soft-red") then return "red" end
  if has(el, "teal") then return "teal" end
  if has(el, "plain") then return "plain" end
  if has(el, "navy") then return "navy" end
  return default or "navy"
end

local function icon_name(el)
  if el.t ~= "Span" then return nil end
  for _, c in ipairs(el.classes) do
    local n = c:match("^bi%-(.+)$")
    if n then
      if not ICONS[n] then
        quarto.log.warning("infoblocks.lua: no Font Awesome name for bi-" .. n)
      end
      return ICONS[n] or FALLBACK_ICON
    end
  end
  return nil
end

-- Inline content without spaces and line breaks.
local function solid(inlines)
  local out = pandoc.List{}
  for _, x in ipairs(inlines) do
    if x.t ~= "Space" and x.t ~= "SoftBreak" and x.t ~= "LineBreak" then out:insert(x) end
  end
  return out
end

local function wrap(inlines, pre, post)
  local out = pandoc.Inlines{ RI(pre) }
  out:extend(inlines)
  out:insert(RI(post))
  return out
end

local function wrapB(blocks, pre, post)
  local out = pandoc.Blocks{ RB(pre) }
  out:extend(blocks)
  out:insert(RB(post))
  return out
end

-- ---------------------------------------------------------- span mapping
local SpanF = {}
function SpanF.Span(el)
  local ic = icon_name(el)
  if ic then
    if has(el, "ic") then
      local cmd = (has(el, "soft") or has(el, "soft-red")) and "\\softicon" or "\\iconcircle"
      return RI(cmd .. "[" .. accent_of(el) .. "]{" .. ic .. "}")
    end
    return RI("\\faIcon{" .. ic .. "}")
  end
  if has(el, "chip") or has(el, "f") then return wrap(el.content, "\\ibchip{", "}") end
  if has(el, "stat") then
    return wrap(el.content, "{\\Large\\bfseries\\color{ib" .. accent_of(el, "red") .. "ink}", "}")
  end
  if has(el, "num") then
    return wrap(el.content, has(el, "xl") and "{\\Large\\bfseries\\color{ibnavy}"
                                            or "{\\bfseries\\color{ibnavy}", "}")
  end
  if has(el, "lbl") or has(el, "small") or has(el, "tag") or has(el, "sub") then
    return wrap(el.content, "{\\tiny\\color{ibtext}", "}")
  end
  if has(el, "quiet") or has(el, "foot-note") then
    return wrap(el.content, "{\\tiny\\color{black!55}", "}")
  end
  if has(el, "ref") then return wrap(el.content, "\\newline{\\tiny\\color{black!55}", "}") end
  if has(el, "fig-title") then return wrap(el.content, "{\\scriptsize\\bfseries\\color{ibnavy}", "}") end
  if has(el, "card-title") or has(el, "on") or has(el, "out") or has(el, "hc") then
    return wrap(el.content, "{\\bfseries ", "}")
  end
  if has(el, "lead") or has(el, "close-2") then return wrap(el.content, "{\\small ", "}") end
  if has(el, "close-1") then return wrap(el.content, "{\\large\\color{ibnavy}", "}") end
  if has(el, "g") then return {} end
  return nil
end

-- LaTeX for inline content, with the span mapping applied.
local function lx(inlines)
  local walked = pandoc.Inlines(inlines):walk(SpanF)
  local s = pandoc.write(pandoc.Pandoc({ pandoc.Plain(walked) }), "latex")
  -- ASCII whitespace only: Lua's %s also matches the byte 0xA0, which ends
  -- many UTF-8 characters (映 = E6 98 A0, ム = E3 83 A0) and would cut them.
  return (s:gsub("^[ \t\r\n]+", ""):gsub("[ \t\r\n]+$", ""))
end

-- ------------------------------------------------------------ layout bits
-- Rows of `widths` columns; items are lists of blocks.
local function grid(items, widths, between)
  local out = pandoc.Blocks{}
  local n = #widths
  for i = 1, #items, n do
    if i > 1 then out:insert(RB("\\vspace{" .. (between or "4pt") .. "}")) end
    out:insert(RB("\\begin{columns}[T,totalwidth=\\textwidth]"))
    for j = 0, n - 1 do
      local it = items[i + j]
      if it then
        out:insert(RB(string.format("\\begin{column}{%.3f\\textwidth}", widths[j + 1])))
        out:extend(it)
        out:insert(RB("\\end{column}"))
      end
    end
    out:insert(RB("\\end{columns}"))
  end
  return out
end

local function even(n)
  local w = {}
  for i = 1, n do w[i] = (n == 1) and 1 or (0.98 - 0.025 * (n - 1)) / n end
  return w
end

local function cols_of(el, default)
  local s = el.attributes.style or ""
  return tonumber(s:match("%-%-cols:%s*(%d+)")) or default
end

-- Card: leading icon-only paragraph and [..]{.card-title} (or .on) give the
-- header; the rest is the body.
local function card(el, group, acc)
  acc = acc or accent_of(el)
  local icon, title = "", nil
  local body = pandoc.Blocks{}
  for _, b in ipairs(el.content) do
    local handled = false
    if (b.t == "Para" or b.t == "Plain") and title == nil then
      local o = solid(b.content)
      if #o == 1 and icon_name(o[1]) then
        icon = icon_name(o[1]); handled = true
      elseif #o >= 1 and o[1].t == "Span" and (has(o[1], "card-title") or has(o[1], "on")) then
        title = pandoc.Inlines{}
        for _, x in ipairs(o[1].content) do
          if icon_name(x) then icon = icon_name(x) else title:insert(x) end
        end
        handled = true
      end
    end
    if not handled then body:insert(b) end
  end
  local opts = group and ("equal height group=" .. group) or ""
  local out = pandoc.Blocks{
    RB("\\begin{infocard}[" .. acc .. "][" .. opts .. "]{" .. icon .. "}{" .. lx(title or {}) .. "}") }
  out:extend(body)
  out:insert(RB("\\end{infocard}"))
  return out
end

-- Tile / chain card: icon, .num, .lbl spans -> \stattile.
local function stattile(el, acc)
  local icon, nums, lbls = "circle-info", {}, {}
  el:walk{ Span = function(s)
    if icon_name(s) then icon = icon_name(s)
    elseif has(s, "num") then nums[#nums + 1] = lx(s.content)
    elseif has(s, "lbl") then lbls[#lbls + 1] = lx(s.content) end
  end }
  return RB("\\stattile[" .. (acc or accent_of(el)) .. "]{" .. icon .. "}{"
            .. table.concat(nums, " ") .. "}{" .. table.concat(lbls, "　") .. "}")
end

-- Spans of class `cls` anywhere inside el, in order.
local function spans(el, cls)
  local found = {}
  el:walk{ Span = function(s) if has(s, cls) then found[#found + 1] = s end end }
  return found
end

-- Icon + label box for icon rows and timelines.
local function iconbox(s, width, acc)
  local icon, rest = FALLBACK_ICON, pandoc.Inlines{}
  for _, x in ipairs(s.content) do
    if icon_name(x) then icon = icon_name(x) else rest:insert(x) end
  end
  return "\\parbox[t]{" .. width .. "}{\\centering\\iconcircle[" .. acc .. "]{" .. icon
         .. "}\\par\\vspace{2pt}{\\tiny " .. lx(rest) .. "\\par}}"
end

local function tabular(spec, rows)
  return RB("{\\tiny\\renewcommand{\\arraystretch}{1.15}\\begin{tabular}{" .. spec .. "}\n"
            .. table.concat(rows, " \\\\\n") .. "\n\\end{tabular}\\par}")
end

-- ---------------------------------------------------------------- blocks
local gid = 0

local function Div(el)
  if has(el, "notes") then return nil end

  if has(el, "cards") or has(el, "org") then
    gid = gid + 1
    local widths = has(el, "org") and { 0.30, 0.12, 0.54 } or even(cols_of(el, 2))
    local n, items, extra = #widths, {}, pandoc.Blocks{}
    for _, c in ipairs(el.content) do
      if c.t == "Div" and (has(c, "card") or has(c, "ob")) then
        local acc = nil
        if has(c, "ob") then
          acc = has(c, "moe") and "red" or has(c, "core") and "navy"
                or has(c, "main") and "teal" or "plain"
        end
        local row = math.floor(#items / n)
        items[#items + 1] = card(c, "ib" .. gid .. "r" .. row, acc)
      elseif c.t == "Div" and has(c, "olink") then
        items[#items + 1] = pandoc.Blocks{ RB("\\vspace{10pt}\\begin{center}\\tiny") }
        items[#items]:extend(c.content)
        items[#items]:insert(RB("\\end{center}"))
      else
        extra:insert(c)
      end
    end
    local out = grid(items, widths)
    out:extend(extra)
    return out
  end

  if has(el, "card") then return card(el, nil) end

  if has(el, "tiles") then
    local n, items = cols_of(el, 2), {}
    for _, c in ipairs(el.content) do
      if c.t == "Div" and has(c, "tile") then items[#items + 1] = pandoc.Blocks{ stattile(c) } end
    end
    if n == 1 then
      local out = pandoc.Blocks{}
      for i, it in ipairs(items) do
        if i > 1 then out:insert(RB("\\vspace{3pt}")) end
        out:extend(it)
      end
      return out
    end
    return grid(items, even(n), "3pt")
  end
  if has(el, "tile") then return stattile(el) end

  if has(el, "chain") then
    local items, widths = {}, {}
    for _, s in ipairs(spans(el, "ccard")) do
      local acc = has(s, "now") and "navy" or "plain"
      items[#items + 1] = pandoc.Blocks{ stattile(s, acc) }; widths[#widths + 1] = 0.28
      items[#items + 1] = pandoc.Blocks{ RB("\\vspace{8pt}{\\color{ibtext}\\faIcon{arrow-right}}") }
      widths[#widths + 1] = 0.04
    end
    items[#items] = nil; widths[#widths] = nil      -- no arrow after the last card
    return grid(items, widths)
  end

  if has(el, "takeaway") then return wrapB(el.content, "\\begin{takeaway}", "\\end{takeaway}") end

  if has(el, "cite") then
    return RB("\\ftnote{" .. lx(pandoc.utils.blocks_to_inlines(el.content)) .. "}")
  end

  if has(el, "center") then return wrapB(el.content, "\\begin{center}", "\\end{center}") end
  if has(el, "iline") then return wrapB(el.content, "{\\footnotesize", "\\par}\\vspace{2pt}") end
  if has(el, "legend") then return {} end

  if has(el, "iconrow") or has(el, "timeline") then
    local cls = has(el, "iconrow") and "it" or "tp"
    local found = spans(el, cls)
    local w = string.format("%.3f\\linewidth", 0.95 / math.max(#found, 1))
    local boxes = {}
    for _, s in ipairs(found) do boxes[#boxes + 1] = iconbox(s, w, has(s, "hl") and "red" or "navy") end
    return RB("\\noindent " .. table.concat(boxes, "\\hfill") .. "\\par")
  end

  if has(el, "factors") then
    local chips = {}
    for _, s in ipairs(spans(el, "f")) do chips[#chips + 1] = "\\ibchip{" .. lx(s.content) .. "}" end
    local out = spans(el, "out")[1]
    return RB("\\begin{columns}[c,totalwidth=\\linewidth]"
      .. "\\begin{column}{0.42\\linewidth}" .. table.concat(chips, "\\par\\vspace{2pt}") .. "\\end{column}"
      .. "\\begin{column}{0.08\\linewidth}{\\color{ibnavy}\\faIcon{arrow-right}}\\end{column}"
      .. "\\begin{column}{0.46\\linewidth}\\begin{takeaway}"
      .. (out and lx(out.content) or "") .. "\\end{takeaway}\\end{column}\\end{columns}")
  end

  if has(el, "units") then
    local rows, rs, us = {}, spans(el, "r"), spans(el, "u")
    for i, r in ipairs(rs) do
      local col = has(r, "hl") and "\\color{ibred}" or "\\color{ibnavy}"
      rows[i] = "{" .. col .. "\\bfseries " .. lx(r.content) .. "} & {"
                .. (has(r, "hl") and "\\color{ibred}\\bfseries " or "")
                .. lx(us[i] and us[i].content or {}) .. "}"
    end
    return tabular("@{}l p{0.72\\linewidth}@{}", rows)
  end

  if has(el, "compare") then
    local n, cells, rows = has(el, "c4") and 4 or 3, {}, {}
    el:walk{ Span = function(s)
      if has(s, "lab") or has(s, "hc") or has(s, "a") or has(s, "b") or has(s, "ha") or has(s, "hb") then
        cells[#cells + 1] = (has(s, "hc") or has(s, "lab")) and ("\\textbf{" .. lx(s.content) .. "}") or lx(s.content)
      end
    end }
    for i = 1, #cells, n do rows[#rows + 1] = table.concat({ table.unpack(cells, i, i + n - 1) }, " & ") end
    return tabular("@{}l" .. string.rep("c", n - 1) .. "@{}", rows)
  end

  if has(el, "steps") then
    local rows, ys, ss = {}, spans(el, "y"), spans(el, "s")
    for i, y in ipairs(ys) do
      rows[i] = "{\\bfseries\\color{ibtealink}" .. lx(y.content) .. "} & " .. lx(ss[i] and ss[i].content or {})
    end
    return tabular("@{}l p{0.62\\linewidth}@{}", rows)
  end

  if has(el, "photos") then
    return el.content:walk{ Image = function(i)
      i.attributes.width = nil; i.attributes.height = "15mm"; return i end }
  end

  if has(el, "booklet") then
    local img, text = nil, pandoc.Blocks{}
    el:walk{ Image = function(i) if not img then img = i end end }
    for _, b in ipairs(el.content) do
      local only_img = b.t == "Para" and #solid(b.content) == 1 and solid(b.content)[1].t == "Image"
      if not only_img then text:insert(b) end
    end
    if not img then return nil end
    img.attributes.width = "100%"; img.attributes.height = nil
    local out = pandoc.Blocks{ RB("\\begin{columns}[T,totalwidth=\\linewidth]\\begin{column}{0.22\\linewidth}") }
    out:insert(pandoc.Para{ img })
    out:insert(RB("\\end{column}\\begin{column}{0.74\\linewidth}"))
    out:extend(text)
    out:insert(RB("\\end{column}\\end{columns}"))
    return out
  end

  if has(el, "figure-frame") then return el.content end
  return nil
end

-- A paragraph that is only a [..]{.stat} span -> \stat (its own paragraph).
local function Para(el)
  local o = solid(el.content)
  if #o == 1 and o[1].t == "Span" and has(o[1], "stat") then
    return RB("\\stat[" .. accent_of(o[1], "red") .. "]{" .. lx(o[1].content) .. "}")
  end
  -- A [..]{.ref} on its own needs no line break before it (\newline would
  -- fail: "There's no line here to end").
  if #o == 1 and o[1].t == "Span" and has(o[1], "ref") then
    return RB("{\\tiny\\color{black!55}" .. lx(o[1].content) .. "\\par}")
  end
  return nil
end

-- Pixel sizes from the 1600 x 900 reveal.js slide -> mm on the 160 mm Beamer slide.
local function Image(el)
  for _, k in ipairs{ "width", "height" } do
    local n = el.attributes[k] and el.attributes[k]:match("^(%d+%.?%d*)px$")
    if n then el.attributes[k] = string.format("%.1fmm", tonumber(n) * 0.1) end
  end
  return el
end

-- Three passes:
-- 1. top-down Div: containers (.cards, .tiles, .org, .card, ...) see their
--    children's original spans (icons, titles) before anything is mapped.
--    Pandoc does not revisit what a top-down handler returns, so
-- 2. a bottom-up pass handles what sits inside the containers (paragraphs of
--    .stat / .ref, .photos, .chips, image sizes), and
-- 3. the span mapping runs last.
return {
  { traverse = "topdown", Div = Div },
  { Div = Div, Para = Para, Image = Image },
  SpanF,
}
