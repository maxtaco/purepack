
purepack = require '../src/main'

compare = (T, s, nm) ->
  enc = "base64"
  e1 = (new Buffer s, 'binary').toString(enc)
  e2 = (new purepack.Buffer).push_bytes(s).toString(enc)
  T.equal e1, e2, nm

compare_all = (T, s, nm) ->
  for i in [0..s.length]
    compare T, s[0..i], "#{nm} [0..#{i}]"

exports.encode_b64 = (T, cb) ->
  s = "Hello my name is foo bar and here is a bunch of tests"
  compare_all T, s, "ascii"
  s = "\x00\x01\x02\x03\x04\xff\xfe\xfd\xee\xe1\xe5\x8f\xaa"
  compare_all T, s, "binary"
  cb()

exports.in_and_out = (T, cb) ->
  corpus = "A boo bar bizzle tizzle \xff\xf3\x00\x33\xaa\xbb\xdd jam jam bye"
  for typ in [ 'base64a', 'base64x', 'base32', 'hex' ]
    for i in [0..corpus.length]
      before = corpus[0..i]
      enc = (new purepack.Buffer).push_bytes(before).toString(typ)
      after = purepack.Buffer.decode(enc,typ).toString('binary')
      T.equal before, after, "#{typ} i=#{i}"
  cb()
    
