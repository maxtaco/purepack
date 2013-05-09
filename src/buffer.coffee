# If possible pick the node-based Buffer;
# otherwise, fallback to the browser-based buffer
# (which also works on node)

# Always include our browser-based buffer so that browserify picks it up
browser = require './browser'

# Include and use our Node-based buffer if it's available, but 
# don't pick up browersify's Buffer, since it's huge and we
# are fine with ours.  If we check for a Buffer? directly,
# we will wind up getting a real buffer object.  We'll assume
# for now (window? XOR Buffer?) is true, though it's not ideal....
exports.PpBuffer = if window?
  console.log "A"
  browser.PpBuffer
else
  console.log "B"
  # This indirection is prevent Browserify from exploring "./node"...
  fn = "./node"
  node = require fn
  node.PpBuffer

exports.force = (which) -> 
  exports.PpBuffer = which
