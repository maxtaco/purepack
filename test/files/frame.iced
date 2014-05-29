purepack = require '../../lib/main'
{tests} = require '../pack/data.js'

eq = (T,a,b,s) ->
  if a? or b? then T.equal(a,b,s)

make_test = (k,v) -> (T,cb) ->
  framed = purepack.frame.pack v.input, {}
  [ret, rem] = purepack.frame.unpack framed
  eq T, v.input, ret, "round trip worked"
  T.equal rem.length, 0, "no remaining frogs"
  cb()

for k,v of tests when not v.difficult
  exports[k] = make_test k, v
