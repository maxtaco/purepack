# If possible pick the node-based Buffer;
# otherwise, fallback to the browser-based buffer
# (which also works on node)

mod = if window? then './browser' else './node'
exports.PpBuffer = require(mod).PpBuffer

exports.force = (which) -> exports.PpBuffer = which
