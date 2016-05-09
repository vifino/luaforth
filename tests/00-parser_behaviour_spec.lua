describe("LuaForth", function()
	it("should not have syntax errors in it's code.", function()
		assert.truthy(pcall(require, "luaforth"))
	end)
	describe("should", function()
		local luaforth = require("luaforth")
		it("shortcut return when the given code is empty.", function()
			local env = {}
			local stack = luaforth.eval("", env)
			assert.are.same(stack, {})
		end)

		it("error when it stack underflows", function()
			local env = {
				pop = {
					_fn = function(stack, env, trash)
						-- do nothing! yay!
					end,
					_args = 1
				}
			}
			assert.has_error(function()
				luaforth.eval("pop", env) -- Stack Underflow!
			end)
		end)
	end)
end)
