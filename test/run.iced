
argv = require('optimist').alias('b', 'browser').boolean('browser').argv

wl = if argv._.length > 0 then argv._ else null

if argv.browser
  buf = require '../src/buffer'
  buf.force require('../src/browser').PpBuffer

require('iced-utils').test.run __filename, null, wl
