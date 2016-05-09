-- LuaForth.
-- Simplistic Forth for Lua interaction.
-- Based on parts of MiniForth

-- The MIT License (MIT)
--
-- Copyright (c) 2016 Adrian Pistol
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


local luaforth = {}

-- Version
luaforth.version = "0.3.1"

-- Word structure:
-- env[name] = {
--	_fn = func -- function that runs the logic
--	_fnret = ["pushtostack", "newstack"] -- wether the function's return values should be added to the stack or _be_ the stack. Defaults to pushtostack.
--	_args = n -- number of arguments which are pop'd from the stack, defaults to 0
--	_parse = ["line"|"word"|"endsign"|"pattern"] -- optional advanced parsing, line passes the whole line to the word, word only the next word, pattern parses given pattern, endsign until...
--	_endsign = string -- the given endsign appears.
--	_pattern = pattern -- pattern for parse option
-- }

-- Method caching, should be a little faster because no global lookup.
local unpack = table.unpack or unpack
local tremove = table.remove
local smatch = string.match
local type, error = type, error
local load = loadstring or load


-- Patterns and stuff for the parser
local genpattparse = function(pat)
	return function(src, pos)
		local capture, newpos = smatch(src, pat, pos)
		if newpos then
			return newpos, capture
		else
			return pos
		end
	end
end
local pattparse = function(src, pos, pat)
	local capture, newpos = smatch(src, pat, pos)
	if newpos then
		return newpos, capture
	else
		return pos
	end
end
local parse_spaces = genpattparse("^([ \t]*)()")
local parse_word   = genpattparse("^([^ \t\r\n]+)()")
local parse_eol    = genpattparse("^(.-)[\r\n]+()")

-- parser
function luaforth.eval(src, env, stack, startpos)
	local pos = startpos or 1
	src = src or ""
	stack = stack or {}

	if src == "" then -- Short cut in case of src being empty
		return stack, startpos
	end

	-- Small fix.
	src = src .. "\n"

	-- Stack
	stack = stack or {}
	local function pop()
		if #stack == 0 then error("Stack underflow!", 0) end
		return tremove(stack)
	end
	local function push(x)
		stack[#stack + 1] = x
	end

	while src ~= "" do -- Main loop
		pos = parse_spaces(src, pos)
		local word_name
		pos, word_name = parse_word(src, pos)
		if word_name then
			local word_value = env[word_name]
			if word_value then -- if the word is in the env
				local word_type = type(word_value)
				if word_type == "table" then -- word
					local f = word_value._fn
					if type(f) == "function" then
						local argn = word_value._args or 0
						local args = {stack, env}
						local pt = word_value._parse
						if pt then -- not just plain word
							pos = parse_spaces(src, pos)
							local extra
							if pt == "line" then
								pos, extra = parse_eol(src, pos)
							elseif pt == "word" then
								pos, extra = parse_word(src, pos)
							elseif pt == "pattern" then
								pos, extra = pattparse(src, pos, "^"..word_value._pattern.."()")
							elseif pt == "endsign" then
								pos, extra = pattparse(src, pos, "^(.-)"..word_value._endsign:gsub(".", "%%%1").."()")
							end
							if not extra then
								error("Failed finding requested "..pt.. " as word argument.", 0)
							end
							args[#args + 1] = extra
						end
						for i=1, argn, 1 do
							args[i+2] = pop()
						end

						local rt = word_value._fnret
						local ra = {f(unpack(args))}
						if rt == "newstack" then
							stack = ra[1]
							local nenv = ra[2]
							if nenv then
								env = nenv
							end
						else
							for i=1, #ra, 1 do
								local e = ra[i]
								if e then
									push(e)
								end
							end
						end
					else
						push(word_value)
					end
				else
					push(word_value)
				end
			else
				local tonword = tonumber(word_name) -- fallback for numbers.
				if tonword then
					push(tonword)
				else
					error("No such word: "..word_name, 0)
				end
			end
		else
			return stack, env
		end
	end
	return stack, env
end

-- Example env that has %L to evaluate the line and [L L] pairs to evalute a small block of Lua code.
luaforth.simple_env = {
	["%L"] = { -- line of lua source
		_fn=function(stack, env, str)
			local f, err = load("return " .. str)
			if err then
				f, err = load(str)
				if err then
					error(err, 0)
				end
			end
			return f(stack, env)
		end,
		_parse = "line"
	},
	["[L"] = { -- same as above, but not the whole line
		_fn=function(stack, env, str)
			local f, err = load("return " .. str)
			if err then
				f, err = load(str)
				if err then
					error(err, 0)
				end
			end
			return f(stack, env)
		end,
		_parse = "endsign",
		_endsign = "L]"
	},
	["s'"] = { -- VERY simple strings, with no way of escaping.
		_fn = function(_, _, str)
			return str
		end,
		_parse = "endsign",
		_endsign = "'"
	},
	["("] = { -- Comment.
		_fn=function() end, -- Do... Nothing!
		_parse = "endsign",
		_endsign = ")"
	},
	["\\"] = {
		_fn=function() end, -- Do nothing once again. Man, I wish I could be as lazy as that function.
		_parse = "line"
	},
	["source"] = { -- source file
		_fn=function(stack, env, loc)
			local f, err = io.open(loc, "r")
			if err then
				error(err, 0)
			end
			local src = f:read("*all")
			f:close()
			return luaforth.eval(src, env, stack)
		end,
		_args = 1,
		_fnret = "newstack"
	},
	["%source"] = { -- shortcut. allows "%source bla.fs\n" syntax.
		_fn=function(stack, env, loc)
			local f, err = io.open(loc, "r")
			if err then
				error(err, 0)
			end
			local src = f:read("*all")
			f:close()
			return luaforth.eval(src, env, stack)
		end,
		_fnret = "newstack",
		_parse = "line"
	}
}

-- Function creation.
luaforth.simple_env[":"] = { -- word definition, arguably the most interesting part of this env.
	_fn = function(_, _, fn)
		local nme, prg = string.match(fn, "^(.-) (.-)$")
		luaforth.simple_env[nme] = {
			_fn = function(stack, env)
				return luaforth.eval(prg, env, stack)
			end,
			_fnret = "newstack"
		}
	end,
	_parse = "endsign",
	_endsign = ";"
}
luaforth.simple_env[":[L"] = { -- word definition using lua!
	_fn = function(stack, env, fn)
		local nme, argno, prg = string.match(fn, "^(.-) (%d-) (.-)$")
		local f, err = load("return " .. prg) -- this is to get the "invisible return" action going.
		if err then
			f, err = load(prg)
			if err then
				error(err, 0)
			end
		end
		env[nme] = {
			_fn=function(_, _, ...)
				return f(...)
			end,
			_args=tonumber(argno)
		}
		return stack, env
	end,
	_parse = "endsign",
	_endsign = "L];",
	_fnret = "newstack" -- to switch out stack and more importantly env
}

return luaforth
