# luaforth
[![Build Status](https://travis-ci.org/vifino/luaforth.svg?branch=master)](https://travis-ci.org/vifino/luaforth) [![Coverage Status](https://coveralls.io/repos/github/vifino/luaforth/badge.svg?branch=master)](https://coveralls.io/github/vifino/luaforth?branch=master)

A simplistic and decently fast base implementation of a Forth parser.

If you expect a fully featured forth here, you're wrong.

This is made for people who want to embed a Forth-like into their project.

# Usage

1. `require`/load luaforth.

2. Create an environment.

3. Call `new_stack, new_environment = luaforth.eval(program_source, environment[, stack, program_source_start_position])`.

Tada!

# Example

See `luaforth.simple_env` [here](https://github.com/vifino/luaforth/blob/master/luaforth.lua#L169-L277) or below.

```lua
-- Example env that has %L to evaluate the line and [L L] pairs to evaluate a small block of Lua code.
local simple_env = {
	["%L"] = {
		_fn=function(stack, env, str)
			local f, err = loadstring("return " .. str)
			if err then
				f, err = loadstring(str)
				if err then
					error(err, 0)
				end
			end
			return f()
		end,
		_parse = "line"
	},
	["[L"] = {
		_fn=function(stack, env, str)
			local f, err = loadstring("return " .. str)
			if err then
				f, err = loadstring(str)
				if err then
					error(err, 0)
				end
			end
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
			end,
			_fnret = "newstack"
		}
	end,
	_parse = "endsign",
	_endsign = ";"
}
```

# Environment

Contains words, strings, booleans, numbers and other things that the forth instance will be able to use.

## Word Structure

Words are Forth jargon for functions.

Look [here](ihttps://github.com/vifino/luaforth/blob/master/luaforth.lua#L33-L41) or below to see how they are structured in this implementation.

```lua
-- Word structure:
-- env[name] = {
--  _fn = func -- function that runs the logic
--  _fnret = ["pushtostack", "newstack"] -- wether the function's return values should be added to the stack or _be_ the stack. Defaults to pushtostack.
--  _args = n -- number of arguments which are pop'd from the stack, defaults to 0
--  _parse = ["line"|"word"|"endsign"|"pattern"] -- optional advanced parsing, line passes the whole line to the word, word only the next word, pattern parses given pattern, endsign until...
--  _endsign = string -- the given endsign appears.
--  _pattern = pattern -- pattern for parse option
-- }
```

# License
MIT
