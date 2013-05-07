# If possible pick the node-based Buffer;
# otherwise, fallback to the browser-based buffer
# (which also works on node)

browser = require './browser'
node    = require './node'

exports.PpBuffer = if window? then browser.PpBuffer else node.PpBuffer

exports.force = (which) -> exports.PpBuffer = which
