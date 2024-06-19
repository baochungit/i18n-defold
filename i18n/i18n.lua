local i18n = {}

local store
local locale
local pluralize_function
local default_locale = "en"
local fallback_locale = default_locale

local plural      = require("i18n.plural")
local interpolate = require("i18n.interpolate")
local variants    = require("i18n.variants")

i18n.plural, i18n.interpolate, i18n.variants = plural, interpolate, variants

-- private stuff

local function load_json_file(path)
  local data, error = sys.load_resource(path)
  if data then
    return json.decode(data)
  end
  print(error)
  return nil
end

local function dot_split(str)
  local fields, length = {},0
    str:gsub("[^%.]+", function(c)
    length = length + 1
    fields[length] = c
  end)
  return fields, length
end

local function is_plural_table(t)
  return type(t) == 'table' and type(t.other) == 'string'
end

local function is_present(str)
  return type(str) == 'string' and #str > 0
end

local function assert_present(function_name, param_name, value)
  if is_present(value) then return end

  local msg = "i18n.%s requires a non-empty string on its %s. Got %s (a %s value)."
  error(msg:format(function_name, param_name, tostring(value), type(value)))
end

local function assert_present_or_plural(function_name, param_name, value)
  if is_present(value) or is_plural_table(value) then return end

  local msg = "i18n.%s requires a non-empty string or plural-form table on its %s. Got %s (a %s value)."
  error(msg:format(function_name, param_name, tostring(value), type(value)))
end

local function assert_present_or_table(function_name, param_name, value)
  if is_present(value) or type(value) == 'table' then return end

  local msg = "i18n.%s requires a non-empty string or table on its %s. Got %s (a %s value)."
  error(msg:format(function_name, param_name, tostring(value), type(value)))
end

local function assert_function_or_nil(function_name, param_name, value)
  if value == nil or type(value) == 'function' then return end

  local msg = "i18n.%s requires a function (or nil) on param %s. Got %s (a %s value)."
  error(msg:format(function_name, param_name, tostring(value), type(value)))
end

local function default_pluralize_function(count)
  return plural.get(variants.root(i18n.get_locale()), count)
end

local function pluralize(t, data)
  assert_present_or_plural('interpolate_plural_table', 't', t)
  data = data or {}
  local count = data.count or 1
  local plural_form = pluralize_function(count)
  return t[plural_form]
end

local function treat_node(node, data)
  if type(node) == 'string' then
    return interpolate(node, data)
  elseif is_plural_table(node) then
    return interpolate(pluralize(node, data), data)
  end
  return node
end

local function recursive_load(current_context, data)
  local composed_key
  for k,v in pairs(data) do
    composed_key = (current_context and (current_context .. '.') or "") .. tostring(k)
    assert_present('load', composed_key, k)
    assert_present_or_table('load', composed_key, v)
    if type(v) == 'string' then
      i18n.set(composed_key, v)
    else
      recursive_load(composed_key, v)
    end
  end
end

local function localized_translate(key, loc, data)
  local path, length = dot_split(loc .. "." .. key)
  local node = store

  for i=1, length do
    node = node[path[i]]
    if not node then return nil end
  end

  return treat_node(node, data)
end

local function localized_text(key, loc)
  local path, length = dot_split(loc .. "." .. key)
  local node = store

  for i=1, length do
    node = node[path[i]]
    if not node then return nil end
  end

  return node
end

-- public interface

function i18n.set(key, value)
  assert_present('set', 'key', key)
  assert_present_or_plural('set', 'value', value)

  local path, length = dot_split(key)
  local node = store

  for i=1, length-1 do
    key = path[i]
    node[key] = node[key] or {}
    node = node[key]
  end

  local lastKey = path[length]
  node[lastKey] = value
end

function i18n.get(key, lc)
  assert_present('translate', 'key', key)
 
  local used_locale = lc or locale

  local fallbacks = variants.fallbacks(used_locale, fallback_locale)
  for i=1, #fallbacks do
    local value = localized_text(key, fallbacks[i])
    if value then return value end
  end
  return nil
end

function i18n.translate(key, data)
  assert_present('translate', 'key', key)

  data = data or {}
  local used_locale = data.locale or locale

  local fallbacks = variants.fallbacks(used_locale, fallback_locale)
  for i=1, #fallbacks do
    local value = localized_translate(key, fallbacks[i], data)
    if value then return value end
  end

  return data.default
end

function i18n.set_locale(new_locale, new_pluralize_function)
  assert_present('set_locale', 'new_locale', new_locale)
  assert_function_or_nil('set_locale', 'new_pluralize_function', new_pluralize_function)
  locale = new_locale
  pluralize_function = new_pluralize_function or default_pluralize_function
end

function i18n.set_fallback_locale(new_fallback_locale)
  assert_present('set_fallback_locale', 'new_fallback_locale', new_fallback_locale)
  fallback_locale = new_fallback_locale
end

function i18n.get_fallback_locale()
  return fallback_locale
end

function i18n.get_locale()
  return locale
end

function i18n.reset()
  store = {}
  plural.reset()
  i18n.set_locale(default_locale)
  i18n.set_fallback_locale(default_locale)
end

function i18n.load(data)
  recursive_load(nil, data)
end

function i18n.load_file(path)
  local data = load_json_file(path)
  i18n.load(data)
end

setmetatable(i18n, {__call = function(_, ...) return i18n.translate(...) end})

i18n.reset()

return i18n
