-- LuaForth.
-- Simplistic Forth for Lua interaction.
-- Based on parts of MiniForth

local luaforth = {}

-- Word structure:
-- env[name] = {
--	_fn = func -- function that runs the logic
--	_args = n -- number of arguments which are pop'd from the stack, defaults to 0
--	_parse = ["line"|"word"|"endsign"|"pattern"] -- optional advanced parsing, line passes the whole line to the word, word only the next word, pattern parses given pattern, endsign until...
--	_endsign = string -- the given endsign appears.
--	_pattern = pattern -- pattern for parse option
-- }

function luaforth.eval(src, env, stack, startpos)
	local unpack = table.unpack or unpack
	local pos = startpos or 1


	local stack = stack or {}
	local function pop()
		local s, r pcall(table.remove, stack, #stack)
		if s then
			return r
		else
			error("Stack underflow!")
		end
	end
	local function push(x)
		stack[#stack + 1] = x
	end

	local genpattparse = function(pat)
		return function()
			local capture, newpos = string.match(src, pat, pos)
			if newpos then
				pos = newpos
				return capture
			end
		end
	end
	local pattparse = function(pat)
		local capture, newpos = string.match(src, pat, pos)
		if newpos then
			pos = newpos
			return capture
		end
	end
	local parse_spaces     = genpattparse("^([ \t]*)()")
	local parse_word       = genpattparse("^([^ \t\n]+)()")
	local parse_newline    = genpattparse("^(\n)()")
	local parse_rest_of_line = genpattparse("^([^\n]*)()")
	local parse_word_or_newline = function () return parse_word() or parse_newline() end
	local get_word          = function () parse_spaces(); return parse_word() end
	local get_word_or_newline = function () parse_spaces(); return parse_word_or_newline() end

	while src ~= "" do
		parse_spaces()
		local word_name = parse_word()
		if word_name then
			local word_value = env[word_name]
			if word_value then
				local word_type = type(word_value)
				if word_type == "table" then -- word
					local f = word_value._fn
					if type(f) == "function" then
						local argn = word_value._args or 0
						local args = {}
						args[1] = stack
						args[2] = env
						for i=1, argn, 1 do
							args[i+2] = pop()
						end
						local pt = word_value._parse
						if pt then -- not just plain word
							parse_spaces()
							local extra 
							if pt == "line" then
								extra = parse_rest_of_line()
							elseif pt == "word" then
								extra = parse_word()
							elseif pt == "pattern" then
								extra = pattparse("^"..word_value._pattern.."()")
							elseif pt == "endsign" then
								extra = pattparse("^(.-)"..word_value._endsign:gsub(".", "%%%1").."()")
							end
							args[#args + 1] = extra
						end

						local ra = {f(unpack(args))}
						for i=1, #ra, 1 do
							local e = ra[i]
							if e then
								push(e)
							end
						end
					else
						push(word_value)
					end
				elseif word_type == "number" or word_type == "boolean" then
					push(word_value)
				else
					error("Invalid type of word in environment: "..word_name, 0)
				end
			else
				local tonword = tonumber(word)
				if tonword then
					push(tonword)
				else
						error("No such word: "..word_name, 0)
				end
			end
		else
			return unpack(stack)
		end
	end
	return unpack(stack)
end

-- Example env that has %L to evaluate the line and [L L] pairs to evalute a small block of lua code.
luaforth.simple_env = {
	["%L"] = {
		_fn=function(stack, env, str)
			local f = loadstring(str)
			return f()
		end,
		_parse = "line"
	},
	["[L"] = {
		_fn=function(stack, env, str)
			local f = loadstring(str)
			return f()
		end,
		_parse = "endsign",
		_endsign = "L]"
	}
}

-- Function creation.
luaforth.simple_env[":"] = {
	_fn = function(stack, env, fn)
		local nme, prg = string.match(fn, "^(.-) (.-)$")
		luaforth.simple_env[nme] = {
			_fn = function(stack, env)
				return luaforth.eval(prg, env, stack)
			end
		}
	end,
	_parse = "endsign",
	_endsign = ";"
}

return luaforth