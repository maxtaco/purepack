
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
  compare T, [0xfff0...0x1000f], "pack3 test 6"
  compare T, [0xfffffff0...0x10000000f], "pack3 test 7"
  compare T, -2147483649, "pack 3 test 8"
  cb()

exports.pack4 = (T, cb) ->
  compare T, [ 1.1, 10.1, 20.333, 44.44444, 5.555555], "various floats"
  compare T, [ -1.1, -10.1, -20.333, -44.44444, -5.555555], "various neg floats"
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

exports.pack6 = (T, cb)  ->
  obj =
    notes : null
    algo_version : 3
    generation : 1
    email : "themax@gmail.com"
    length : 12
    num_symbols : 0
    security_bits : 8 
  compare T, obj, "pack6"
  cb()

exports.pack7 = (T, cb)  ->
  obj = "themax@gmail.com"
  compare T, obj, "pack7"
  cb()

exports.pack8 = (T, cb)  ->
  d = {}
  obj = d.yuck
  compare T, obj, "pack8"
  cb()

exports.pack9 = (T,cb) ->
  obj = (i for i in [1...100]).join ' '
  compare T, obj, "pack9a"
  d = { obj }
  compare T, obj, "pack9b"
  cb()

exports.pack10 = (T,cb) ->
  obj = (i for i in [1...30000]).join ' '
  compare T, obj, "pack10a"
  d = { obj }
  compare T, obj, "pack10b"
  cb()
