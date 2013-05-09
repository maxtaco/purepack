
ICED=node_modules/.bin/iced
BROWSERIFY=node_modules/.bin/browserify


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

test/pack/data.js: test/pack/generate.iced test/pack/input.iced
	$(ICED) test/pack/generate.iced > $@

test: test/pack/data.js
	$(ICED) test/run.iced

test/browser/test.js: test/browser/main.iced | build
	$(BROWSERIFY) -t icsify $< > $@

test-browser: test/browser/test.js

clean:
	rm -f lib/*.js test/compare/data.js

default: build
all: build

setup:
	npm install -d

.PHONY: clean setup