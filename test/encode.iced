
purepack = require '../src/main.coffee'


m0 = "hello"
m1 = "Hello my name is foo bar and here is a bunch of tests"
m2 = "\x00\x01\x02\x03\x04\xff\xfe\xfd\xee\xe1\xe5\x8f\xaa"
m3 = "A boo bar bizzle tizzle \xff\xf3\x00\x33\xaa\xbb\xdd jam jam bye"

compare = (T, s, nm) ->
  enc = "base64"
  e1 = (new Buffer s, 'binary').toString(enc)
  e2 = (new purepack.Buffer).push_raw_bytes(s).toString(enc)
  T.equal e1, e2, nm

compare_all = (T, s, nm) ->
  for i in [0..s.length]
    compare T, s[0..i], "#{nm} [0..#{i}]"

exports.base32_simple = (T, cb) ->
  before = m3[0...20]
  enc = (new purepack.Buffer).push_raw_bytes(before).toString('base32')
  back = purepack.Buffer.decode(enc,'base32').toString('binary')
  T.equal before, back, "simple base32"
  cb()

exports.encode_b64 = (T, cb) ->
  compare_all T, m1, "ascii"
  compare_all T, m2, "binary"
  cb()

exports.in_and_out = (T, cb) ->
  for typ in [ 'base64a', 'base64x', 'base32', 'hex', 'binary' ]
    for i in [0..m3.length]
      before = m3[0..i]
      enc = (new purepack.Buffer).push_raw_bytes(before).toString(typ)
      after = purepack.Buffer.decode(enc,typ).toString('binary')
      T.equal before, after, "#{typ} i=#{i}"
  cb()

test_ui8a_encoding = (T, m, note) ->
  buf = purepack.Buffer.decode m, "binary"
  ui8a = buf.encode 'ui8a'
  buf2 = purepack.Buffer.decode ui8a, "ui8a"
  after = buf2.toString 'binary'
  T.equal m, after, "null encoding #{note}"
  
exports.null_encoding = (T, cb) ->
  test_ui8a_encoding T, m1, "ascii"    
  test_ui8a_encoding T, m2, "binary"    
  test_ui8a_encoding T, m3, "mixed"
  cb()
