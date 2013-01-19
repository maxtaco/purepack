
purepack = require '../src/main'

exports.test_convert_doubles = (T, cb) ->

  v = [ 1.0, -1.0, 122.222, -122.333, 344.999, 10000000.3, -100000.3 ]
  for f in v
    buf = new purepack.Buffer
    conv = new purepack.FloatConverter.make buf
    conv.pack_float64 f
    out = conv.consume_float64()
    T.equal f, out, "Encoding #{f} #{out}"
  cb()
