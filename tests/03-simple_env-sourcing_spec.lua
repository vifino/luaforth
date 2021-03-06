describe("LuaForth", function()
	local luaforth = require("luaforth")
	describe("should, when given simple_env, be able to source 03-simple_env-sourcing.fs using", function()
		it("%source", function()
			local stack = luaforth.eval("%source tests/03-simple_env-sourcing.fs", luaforth.simple_env)
			assert.are.same(stack[1], "Works!")
		end)
		it("source", function()
			local stack = luaforth.eval("s' tests/03-simple_env-sourcing.fs' source", luaforth.simple_env)
			assert.are.same(stack[1], "Works!")
		end)
	end)
end)
