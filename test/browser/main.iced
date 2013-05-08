
mods = 
  encode : require '../files/encode.iced'
  extensions : require '../files/extensions.iced'
  unpack : require '../files/unpack.iced'

{BrowserRunner} = require('iced-test')

window.onload = () ->
  br = new BrowserRunner { log : "log", rc : "rc" }
  await br.run mods, defer rc
