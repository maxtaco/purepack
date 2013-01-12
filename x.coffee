bm = require './buffer'


test = (w) ->
  x = new bm.Buffer()
  x.push_bytes w
  e1 = x.toString 'base64'
  e2 = (new Buffer w, 'binary').toString 'base64'
  if e1 isnt e2
   console.log e1
   console.log e2
   console.log "fuck #{w}"


for x in [ "b", "bc", "def", "food", "jelly", "\x11\x23\xff\xfe\xef" ]
  test x
