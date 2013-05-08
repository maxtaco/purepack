
mods = 
  encode : require '../files/encode.iced'
  extensions : require '../files/extensions.iced'
  unpack : require '../files/unpack.iced'

{BrowserRunner} = require('iced-test')

br = new BrowserRunner { log : "log-div", rc : "rc-div" }
await br.run mods, defer rc
