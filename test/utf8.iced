
purepack = require '../src/main'

compare = (T, obj, nm) -> 
  enc = "base64"
  packed = purepack.pack obj, enc
  [err, unpacked] = purepack.unpack packed, enc
  T.assert (not err?)
  T.equal obj, unpacked, nm

exports.utf8_test1 = (T,cb) ->
  compare T, "hello メインページ", "japanese!"
  cb()

exports.utf8_test2 = (T,cb) ->
  compare T, "この説明へのリンクにアクセスできる方法はいくつかあり、このエリアに至るまでの経路もいくつかあ", "japanese 2"
  cb()

exports.random_binary = (T,cb)->
  compare T, "\xaa\xbc\xce\xfe"
  cb()

exports.random_binary = (T,cb)->
  compare T, (String.fromCharCode(i & 0xff) for i in [0...10000])
  cb()

