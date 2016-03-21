# LuaForth Makefile

TESTS=$(wildcard tests/*.lua)

test: ${TESTS}
	busted $<

lint: luaforth.lua ${TESTS}
	luacheck $<

all: test
