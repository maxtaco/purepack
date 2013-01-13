
msgpack = require 'msgpack2'
purepack = require '../src/main'

compare = (T, obj, nm) ->
  enc = "base64"
  b1 = msgpack.pack obj
  e1 = b1.toString enc
  e2 = purepack.pack(obj,enc)
  T.equal e1, e2, nm


exports.pack1 = (T, cb) ->
  compare T, "hello", "pack1"
  cb()

exports.pack2 = (T, cb) ->
  compare T, { hi : "mom", bye : "dad" }, "pack2"
  cb()
  
exports.pack3 = (T, cb) ->
  compare T, [-100..100], "pack3 test 1"
  compare T, [-1000..1000], "pack3 test 2"
  compare T, [-1000..1000], "pack3 test 2"
  compare T, [-32800...-32700], "pack3 test 4"
  compare T, [-2147483668...-2147483628], "pack3 test 5"
  cb()

exports.pack5 = (T, cb) ->
  
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
  compare T, obj, "pack5"
  cb()
  

