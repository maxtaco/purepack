
##=======================================================================

exports.Converter = class Converter
  constructor : (@_buffer) ->
  pack_float32: (v) -> @_pack_float v, 4
  pack_float64: (v) -> @_pack_float v, 8
  consume_float32 : () -> @_consume_float 4
  consume_float64 : () -> @_consume_float 8

  @make : (b) ->
    klass = if DataView? and ArrayBuffer? and Uint8Array? then Browser
    else if Buffer? then Node
    else null
    if klass? then new klass b else null

##=======================================================================

exports.Browser = class Browser extends Converter

  _pack_float : (v,n) ->
    ab = new ArrayBuffer n
    ia = new Uint8Array ab
    dv = new DataView ab
    dv["setFloat#{n << 3}"].call dv, 0, v, false
    @_buffer.push_buffer ia

  _consume_float : (n) ->
    ab = new ArrayBuffer n
    ia = new Uint8Array ab
    dv = new DataView ab
    ia[i] = b for b,i in @_buffer.consume_bytes n
    dv["getFloat#{n << 3}"].call dv, 0, false
    
##=======================================================================

exports.Node = class Node extends Converter
  _pack_float : (v,n) ->
    b = new Buffer n
    f = if n is 4 then "writeFloatBE" else "writeDoubleBE"
    b[f].call(b, v, 0)
    
  _consume_float : (n) ->
    b = new Buffer @_buffer.consume_bytes n
    f = if n is 4 then "readFloatBE" else "readDoubleBE"
    b[f].call(b, 0)

##=======================================================================
