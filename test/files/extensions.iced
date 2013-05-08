
purepack =  require '../../src/main.coffee'
crypto = require 'crypto'

ui8a_compare = (a, b) ->
  return false unless a.length is b.length
  for i in [0...a.length]
    return false unless a[i] is b[i]
  return true

compare = (T, obj, nm) ->
  enc = "base64"
  packed = purepack.pack obj, enc, { byte_arrays : true }
  [err, unpacked] = purepack.unpack packed, enc
  T.assert (not err?), "No errors in #{nm}"
  T.assert ui8a_compare(obj, unpacked), "Array compare in #[nm}"

exports.test1 = (T, cb) ->
  a = new Uint8Array( [0..0xff] )
  compare T, a, "test1 0 through 0xff"
  cb()

random_array = (n) ->
  new Uint8Array crypto.prng n
   
exports.random1 = (T,cb) ->
  a = new Uint8Array crypto.prng 0x10000
  compare T, a, "prng-generated array"
  cb()

exports.random2 = (T,cb) ->
  a = new Uint8Array crypto.prng 0x10000
  obj =
    aaa : random_array 1000
    bbbb : [ (random_array 10000), 1, 2, 3]
    ccc :
      dd : random_array 0x1000
  compare T, obj, "prng-generated object"
  cb()
