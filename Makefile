# LuaForth Makefile

TESTS=$(wildcard tests/*.lua)

test: ${TESTS}
	busted $<
