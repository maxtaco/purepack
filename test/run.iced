
wl = if process.argv.length > 2 then process.argv[2...] else null
require('iced-utils').test.run __filename, null, wl
