mpack = require 'msgpack'
purepack = require '../src/main'

compare = (T, obj, nm) -> 
  enc = "base64"
  packed = purepack.pack obj, enc
  mpacked = mpack.pack(obj).toString('base64') 
  T.equal packed, mpacked
  [err, unpacked] = purepack.unpack packed, enc
  T.assert (not err?)
  T.equal obj, unpacked, nm

exports.utf8_test1 = (T,cb) ->
  compare T, "hello メインページ", "japanese!"
  cb()

exports.utf8_test2 = (T,cb) ->
  compare T, "この説明へのリンクにアクセスできる方法はいくつかあり、このエリアに至るまでの経路もいくつかあ", "japanese 2"
  cb()

exports.utf8_test3 = (T,cb) ->
  compare T, "다국어 최상위 도메인 중 하나의 평가 영역입니다", "Korean"
  cb()

# Gothic characters are higher than 0x10000 so these guys can't
# be manipulated with String.fromCharCode....
exports.utf8_test4 = (T,cb) ->
  compare T, "𐌼𐌰𐌲 𐌲𐌻𐌴𐍃 𐌹̈𐍄𐌰𐌽, 𐌽𐌹 𐌼𐌹𐍃 𐍅𐌿 𐌽𐌳𐌰𐌽 𐌱𐍂𐌹𐌲𐌲𐌹𐌸", "gothic"
  cb()

exports.random_binary = (T,cb)->
  compare T, "\xaa\xbc\xce\xfe"
  cb()

exports.random_binary = (T,cb)->
  compare T, (String.fromCharCode(i & 0xff) for i in [0...10000])
  cb()

