mpack = require 'msgpack'
purepack = require '../../lib/main'

compare = (T, obj, nm) -> 
  enc = "base64"
  packed = purepack.pack obj, enc
  mpacked = mpack.pack(obj).toString('base64') 
  T.equal packed, mpacked
  [err, unpacked] = purepack.unpack packed, enc
  T.assert (not err?)
  T.equal obj, unpacked, nm

exports.random_binary = (T,cb)->
  compare T, (String.fromCharCode(i & 0xff) for i in [0...10000])
  cb()

