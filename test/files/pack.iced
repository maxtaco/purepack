purepack = require '../../lib/main'

{tests} = require '../pack/data.js'

for k,v of tests
  exports[k] = (T, cb) ->
    mine = purepack.pack v.input, 'base64'
    T.equal mine, v.output, "Compare to msgpack4 in #{k}"
    [err, unpacked] = purepack.unpack mine, 'base64'
    T.assert((not err?), "Got error #{err} in #{k}")
    T.equal unpacked, v.input, "Round trip failure in #{k}"
    cb()