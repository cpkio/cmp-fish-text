local dataservice = require"fish-text.dataservice"

local source = {}

local variants = {
  {
    type = "para",
    label = "Random Paragraph",
    f = dataservice.paragraph(dataservice),
    l = function() return #dataservice.data.paragraphs end
  },
  {
    type = "sentence",
    label = "Random Sentence",
    f = dataservice.sentence(dataservice),
    l = function() return #dataservice.data.sentences end
  },
  {
    type = "title",
    label = "Random Title",
    f = dataservice.title(dataservice),
    l = function() return #dataservice.data.titles end
  }
}

function source.new()
  for _,v in ipairs(variants) do v.f() end
  return setmetatable({}, { __index = source })
end

function source:is_available()
  dataservice:dispatcher()
  return true
end

function source:get_keyword_pattern()
  return [[\k\+]]
end

function source:execute(item, callback)
  dataservice.unloader(dataservice, item)
end

-- function source:resolve(item, callback)
-- end

function source:complete(request, callback)
  local items = {}
  for _, v in pairs(variants) do
    table.insert(items, {
      filterText = nil,
      label = v.label .. " (" .. v.l() .. ")",
      insertText = v.f(),
      documentation = nil,
      type = v.type
    })
  end
  callback({
    items = items
  })
end

return source
