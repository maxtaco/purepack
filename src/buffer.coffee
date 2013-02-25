# If possible pick the node-based Buffer;
# otherwise, fallback to the browser-based buffer
# (which also works on node)

mod = if Buffer? then './node' else './browser'
exports.Buffer = require(mod).Buffer

exports.force = (which) -> exports.Buffer = which
