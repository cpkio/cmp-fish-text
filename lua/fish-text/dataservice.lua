-- local http = require"socket.http"
local https = require"ssl.https"
local ltn12 = require"ltn12"

local split_sentences = [[\%(\.\|\x3F\|!\)\@1<= ]]
local split_paragraphs = [[\\n\\n]]

local function stringbuilder(parameters)
  local stringb = ''
  if type(parameters) ~= "table" then return end
  for k, v in pairs(parameters) do
    stringb = stringb .. tostring(k) .. '=' .. tostring(v) .. '&'
  end
  stringb = string.sub(stringb, 1, #stringb - 1)
  return stringb
end

local function request(parameters, splitpattern)
  local splitpattern = splitpattern or split_paragraphs
  local response_body = {}

  local res, code, response_headers = https.request{
      url = "https://fish-text.ru/get" .. "?" .. stringbuilder(parameters),
      method = "GET",
      headers = {
        ["Content-Type"] = "text/plain";
        -- ["Content-Length"] = #request_body;
      },
      -- source = ltn12.source.string(request_body),
      sink = ltn12.sink.table(response_body),
      maxredirects = false
  }

  if type(response_body) == "table" then
    return vim.fn.split(vim.fn.json_decode(table.concat(response_body)).text, splitpattern, false)
  else
    return nil
  end
end

local function lookup(data, element)
  for k,v in pairs(data) do
    if v == element then
      table.remove(data, k)
    end
  end
end

local Service = {
  data = {
    titles = { "Loading…" },
    sentences = { "Loading…" },
    paragraphs = { "Loading…" }
  },
  tasks = {}
}

function Service:new(v)
  local v = v or {}
  self.__index = self
  setmetatable(v, self)
  return v
end

-- from Programming in Lua as is
function Service:dispatcher()
  local i = 1
  while true do
    if self.tasks[i] == nil then
      if self.tasks[1] == nil then
        break
      end
      i = 1
    end
    local res = self.tasks[i]()
    if not res then
      table.remove(self.tasks, i)
    else
      i = i + 1
    end
  end
end

function Service:unloader(item)
  if item.type == "title" then
    lookup(self.data.titles, item.insertText)
  end
  if item.type == "para" then
    lookup(self.data.paragraphs, item.insertText)
  end
  if item.type == "sentence" then
    lookup(self.data.sentences, item.insertText)
  end
end

function Service:title()
  return coroutine.wrap(function()
    while true do
      if #self.data.titles < 3 then
        local co = coroutine.wrap(function() self.data.titles = request( { type = "title", number = 10 } ) end)
        table.insert(self.tasks, co)
      end
      coroutine.yield(
        self.data.titles[math.random(1,#self.data.titles)]
      )
    end
  end)
end


function Service:sentence()
  return coroutine.wrap(function()
    while true do
      if #self.data.sentences < 3 then
        local co = coroutine.wrap(function() self.data.sentences = request( { type = "sentence", number = 10 }, split_sentences) end)
        table.insert(self.tasks, co)
      end
      coroutine.yield(
        self.data.sentences[math.random(#self.data.sentences)]
      )
    end
  end)
end

function Service:paragraph()
  return coroutine.wrap(function()
    while true do
      if self.data.paragraphs == nil or #self.data.paragraphs < 3 then
        local co = coroutine.wrap(function() self.data.paragraphs = request( { type = "paragraph", number = 10 }, split_paragraphs) end)
        table.insert(self.tasks, co)
      end
      coroutine.yield(
        self.data.paragraphs[math.random(#self.data.paragraphs)]
      )
    end
  end)
end

return Service:new()
