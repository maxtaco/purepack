
purepack = require '../../lib/main'

exports.sort_check_1 = (T,cb) ->
  obj =
    cat : 1
    dog : 2
    apple : 3
    tree : 4
    bogey : 5
    zebra : 6
    echo : 7
    yankee : 8
    golf : 9
  packed = purepack.pack obj, { sort_keys : false }
  err = null
  try
    purepack.unpack packed, { strict : true }
  catch e
    err = e
  T.assert err?, "threw an error on lack of sorting"
  packed = purepack.pack obj, { sort_keys : true }
  res = purepack.unpack packed, { strict : true }
  T.assert res?, "sorted check passed"
  cb()

exports.strict_check_duplicate_keys_1 = (T,cb) ->
  key = purepack.pack "key"
  v1 = purepack.pack 1
  v2 = purepack.pack 2
  dict = Buffer.concat [
    new Buffer([ 0x82 ] ), # fixed map with 2 elements
    key  # "key"
    v1   # 1
    key  # "key"
    v2   # 2
  ]
  res = err = null
  try
    res = purepack.unpack dict, { strict : false }
  catch e
    err = e
  T.assert err?, "multiple keys fail even in strict mode"
  T.equal err.message, "duplicate key 'key'"
  cb()

exports.strict_check_understuffed_map = (T,cb) ->
  n = Buffer.concat [
    new Buffer([0xde, 0x00, 0x01 ]) # A 16-bit-sized buffer, with just 1 item
    purepack.pack("key"),
    purepack.pack(2)
  ]
  res = err = null
  try
    res = purepack.unpack n, { strict : true }
  catch e
    err = e
  T.assert err?, "understuffed map failure in strict mode"
  T.equal err.message, "encoding size mismatch: wanted 6 but got 8"

  n = Buffer.concat [
    new Buffer([0xdf, 0x00, 0x00, 0x00, 0x01 ]) # A 16-bit-sized buffer, with just 1 item
    purepack.pack("key"),
    purepack.pack(2)
  ]
  res = err = null
  try
    res = purepack.unpack n, { strict : true }
  catch e
    err = e
  T.assert err?, "understuffed map failure in strict mode"
  T.equal err.message, "encoding size mismatch: wanted 6 but got 10"

  cb()

exports.strict_check_understuffed_array = (T,cb) ->
  n = Buffer.concat [
    new Buffer([0xdc, 0x00, 0x01 ]) # A 16-bit-sized buffer, with just 1 item
    purepack.pack(2)
  ]
  res = err = null
  try
    res = purepack.unpack n, { strict : true }
  catch e
    err = e
  T.assert err?, "understuffed array failure in strict mode"
  T.equal err.message, "encoding size mismatch: wanted 2 but got 4"

  n = Buffer.concat [
    new Buffer([0xdd, 0x00, 0x00, 0x00, 0x01 ]) # A 16-bit-sized buffer, with just 1 item
    purepack.pack(2)
  ]
  res = err = null
  try
    res = purepack.unpack n, { strict : true }
  catch e
    err = e
  T.assert err?, "understuffed array failure in strict mode"
  T.equal err.message, "encoding size mismatch: wanted 2 but got 6"

  cb()

exports.strict_check_understuffed_string = (T,cb) ->

  # Test "abcd" encoded with understuffing a few different ways..

  # the 8-bit fixed case
  n = new Buffer([0xd9, 0x04, 0x61, 0x62, 0x63, 0x64 ])
  res = err = null
  try
    res = purepack.unpack n, { strict : true }
  catch e
    err = e
  T.assert err?, "understuffed array failure in strict mode"
  T.equal err.message, "encoding size mismatch: wanted 5 but got 6"

  # the 16-bit fixed case
  n = new Buffer([0xda, 0x0, 0x04, 0x61, 0x62, 0x63, 0x64 ])
  res = err = null
  try
    res = purepack.unpack n, { strict : true }
  catch e
    err = e
  T.assert err?, "understuffed array failure in strict mode"
  T.equal err.message, "encoding size mismatch: wanted 5 but got 7"

  # the 32-bit fixed case
  n = new Buffer([0xdb, 0x0, 0x0, 0x0, 0x04, 0x61, 0x62, 0x63, 0x64 ])
  res = err = null
  try
    res = purepack.unpack n, { strict : true }
  catch e
    err = e
  T.assert err?, "understuffed array failure in strict mode"
  T.equal err.message, "encoding size mismatch: wanted 5 but got 9"

  cb()


