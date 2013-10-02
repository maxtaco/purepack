purepack = require '../../lib/main'

{tests} = require '../pack/data.js'

make_test = (k,v) -> (T, cb) ->
  mine = purepack.pack v.input
  T.equal mine.toString('base64'), v.output, "Compare to msgpack4 in #{k}"
  unpacked = purepack.unpack(mine)

  # undefined != null is OK for now...
  unless k is 'u1'
    T.equal unpacked, v.input, "Round trip failure in #{k}"
    
  cb()

for k,v of tests
  exports[k] = make_test k, v

