
msgpack = require 'msgpack2'
purepack = require '../src/main'

compare = (T, obj, nm) ->
  enc = "base64"
  packed = purepack.pack obj, enc
  [err, unpacked] = purepack.unpack packed, enc
  T.assert (not err?)
  T.equal obj, unpacked, nm

exports.unpack1 = (T, cb) ->
  compare T, "hello", "unpack1"
  cb()

exports.unpack2 = (T, cb) ->
  compare T, { hi : "mom", bye : "dad" }, "unpack2"
  cb()
  
exports.unpack3 = (T, cb) ->
  compare T, -100, "unpack3 test 0"
  compare T, -32800, "unpack3 test 0b"
  compare T, [-100..100], "unpack3 test 1"
  compare T, [-1000..1000], "unpack3 test 2"
  compare T, [-1000..1000], "unpack3 test 2"
  compare T, [-32800...-32700], "unpack3 test 4"
  compare T, [-2147483668...-2147483628], "unpack3 test 5"
  compare T, [0xfff0...0x1000f], "unpack3 test 6"
  compare T, [0xfffffff0...0x10000000f], "unpack3 test 7"
  compare T, -2147483649, "unpack 3 test 8"
  cb()

exports.unpack5 = (T, cb) ->
  
  obj =
    foo : [0..10]
    bar :
      bizzle : null
      jam : true
      jim : false
      jupiter : "abc ABC 123"
      saturn : 6
    bam :
      boom :
        yam :
          potato : [10..20]
  compare T, obj, "unpack5"
  cb()
  

