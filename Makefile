
ICED=node_modules/.bin/iced

lib/%.js: src/%.coffee
	$(ICED) -I none -c -o lib $<

build: lib/main.js \
	lib/base.js \
	lib/browser.js \
	lib/buffer.js \
	lib/const.js \
	lib/node.js \
	lib/pack.js \
	lib/unpack.js \
	lib/util.js

test/compare/data.js: test/compare/generate.iced test/compare/input.iced
	$(ICED) test/compare/generate.iced > $@

clean:
	rm -f lib/*.js test/compare/data.js

.PHONY: clean