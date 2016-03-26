-- LuaForth.
-- Simplistic Forth for Lua interaction.
-- Based on parts of MiniForth

local luaforth = {}

-- Version
luaforth.version = "0.1"

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

function luaforth.eval(src, env, stack, startpos)
	if src == "" then -- Short cut in case of src being empty
		return stack, startpos
	end

	-- Small fix.
	src = src .. "\n"

	local pos = startpos or 1


	-- Stack
	stack = stack or {}
	local function pop()
		if #stack == 0 then error("Stack underflow!") end
		return tremove(stack)
	end
	local function push(x)
		stack[#stack + 1] = x
	end

	-- Patterns and stuff for the parser
	local genpattparse = function(pat)
		return function()
			local capture, newpos = smatch(src, pat, pos)
			if newpos then
				pos = newpos
				return capture
			end
		end
	end
	local pattparse = function(pat)
		local capture, newpos = smatch(src, pat, pos)
		if newpos then
			pos = newpos
			return capture
		end
	end
	local parse_spaces = genpattparse("^([ \t]*)()")
	local parse_word   = genpattparse("^([^ \t\r\n]+)()")
	local parse_eol    = genpattparse("^(.-)[\r\n]+()")

	while src ~= "" do -- Main loop
		parse_spaces()
		local word_name = parse_word()
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
							parse_spaces()
							local extra
							if pt == "line" then
								extra = parse_eol()
							elseif pt == "word" then
								extra = parse_word()
							elseif pt == "pattern" then
								extra = pattparse("^"..word_value._pattern.."()")
							elseif pt == "endsign" then
								extra = pattparse("^(.-)"..word_value._endsign:gsub(".", "%%%1").."()")
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

-- Example env that has %L to evaluate the line and [L L] pairs to evalute a small block of lua code.
luaforth.simple_env = {
	["%L"] = { -- line of lua source
		_fn=function(stack, env, str)
			local f, err = loadstring("return " .. str)
			if err then
				f, err = loadstring(str)
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
			local f, err = loadstring("return " .. str)
			if err then
				f, err = loadstring(str)
				if err then
					error(err, 0)
				end
			end
			return f(stack, env)
		end,
		_parse = "endsign",
		_endsign = "L]"
	},
	["("] = { -- Comment.
		_fn=function() end, -- Do... Nothing!
		_parse = "endsign",
		_endsign = ")"
	},
	["\\"] = {
		_fn=function() end, -- Do nothing once again. Man, I wish I could be as lazy as that function.
		_parse = "line"
	}
}

-- Function creation.
luaforth.simple_env[":"] = { -- word definiton, arguebly the most interesting part of this env.
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
		local f, err = loadstring("return " .. prg) -- this is to get the "invisible return" action going.
		if err then
			f, err = loadstring(prg)
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
