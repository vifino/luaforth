# luaforth

A simplistic and decently fast base implementation of a Forth parser.

If you expect a fully featured forth here, you're wrong.

This is made for people who want to embed a Forth-like into their project.

# Usage

1. `require`/load luaforth.

2. Create an environment.

3. Call `luaforth.eval(program_source, environment)`.

# Example

See `luaforth.simple_env` in `luaforth.lua` or below.

```lua
-- Example env that has %L to evaluate the line, [L L] pairs to evalute a small block of lua code and...
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

-- function creation!
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
```

# License
MIT
