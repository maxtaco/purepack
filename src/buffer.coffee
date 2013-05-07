# If possible pick the node-based Buffer;
# otherwise, fallback to the browser-based buffer
# (which also works on node)

# Always include our browser-based buffer so that browserify picks it up
browser = require './browser'

# Include and use our Node-based buffer if it's available, but 
# don't pick up browersify's Buffer, since it's huge and we
# are fine with ours....
node    = require './node' if eval("typeof(Buffer) !== 'undefined' && Buffer !== null")

exports.PpBuffer = if node? then node.PpBuffer else browser.PpBuffer

exports.force = (which) -> exports.PpBuffer = which
