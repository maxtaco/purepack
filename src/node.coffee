
BaseBuffer = require('./base').Buffer

##=======================================================================

exports.Buffer = class NodeBuffer extends BaseBuffer

  #-----------------------------------------

  constructor : () ->
    super()
    @_frozen_buf = null
    @_buffers = []
    @_limits = []
    @_sz = 0x1000
    @_logsz = 12
    @_i = 0
    @_tot = 0
    @_cp = 0

  #-----------------------------------------

  @decode = (s, enc) -> BaseBuffer._decode NodeBuffer, s, enc

  #-----------------------------------------

  _nb  : () -> @_buffers.length     # num buffers
  _ab  : () -> @_buffers[@_nb()-1]  # active buffer
  _lib : () -> 0                    # we'll update this later..

  #-----------------------------------------

  _finish_buffer : () ->
    @_limits.push @_i
    @_i = 0

  #-----------------------------------------

  _push_buffer : (b) ->
    @_finish_buffer() if @_buffers.length
    @_lib = () -> @_sz - @_i
    @_buffers.push b
    b

  #-----------------------------------------

  _push_new_buffer : () -> @_push_buffer new Buffer @_sz

  #-----------------------------------------
  
  push_uint8 : (b) ->
    throw new Error "Cannot push anymore into this buffer" if @_no_push
    buf = if @_lib() is 0 then @_push_new_buffer() else @_ab()
    buf[@_i++] = b
    @_tot++

  push_int8 : (b) -> @push_uint8 b

  push_uint16 : (s) -> 
    n = 2
    if @_lib() < n then @_push_new_buffer()
    @_ab().writeUint16BE s, @_i
    @_i += n
    @_tot += n

  push_uint32 : (i) ->
    n = 4
    if @_lib() < n then @_push_new_buffer()
    @_ab().writeUint32BE s, @_i
    @_i += n
    @_tot += n

  push_int16 : (s) -> 
    n = 2
    if @_lib() < n then @_push_new_buffer()
    @_ab().writeInt16BE s, @_i
    @_i += n
    @_tot += n

  push_int32 : (i) ->
    n = 4
    if @_lib() < n then @_push_new_buffer()
    @_ab().writeInt32BE s, @_i
    @_i += n
    @_tot += n

  push_raw_bytes : (s) ->
    @push_buffer( new Buffer s, 'binary' )

  push_buffer : (b) ->
    if b.length > Math.min(0x400, @_sz)
      @_push_buffer b
      @_push_new_buffer()
    else
      n = Math.min b.length, @_lib()
      if n > 0
        b.copy @_ab(), @_i, 0, n
        @_i += n
        @_tot += n
      if n < b.length
        @_push_new_buffer()
        b.copy @_ab(), @_i, n, b.length
        diff = b.length - n
        @_i += diff
        @_tot += diff
    @

  #-----------------------------------------

  _freeze : () ->
    if not @_frozen_buf?
      @_finish_buffer()
      lst = for b,i in @_buffers
        if (l = @_limits[i]) is b.length then b
        else b[0...l]
      @_buffers = []
      @_frozen_buf = Buffer.concat lst, @_tot
    @_frozen_buf

  #-----------------------------------------

  _freeze_to : (b) ->
    @_frozen_buf = b
    @_tot = b.length
    @_buffers = []
    @

  #-----------------------------------------

  _prepare_encoding : () -> @_freeze()

  #-----------------------------------------

  base64_encode : () -> @_freeze().toString 'base64'
  base16_encode : () -> @_freeze().toString 'hex'
  binary_encode : () -> @_freeze().toString 'binary'
  ui8a_encode   : () -> new Uint8Array @_freeze()

  base64_decode : (d) -> @_freeze_to( new Buffer d, 'base64' )
  base16_decode : (d) -> @_freeze_to( new Buffer d, 'hex'    )
 
  #-----------------------------------------

  _get : (i) -> if i < @_tot then @_frozen_buf[i] else 0

  #-----------------------------------------

  # same as in Browser's buffer
  ui8a_decode : (v) ->
    @_buffers = [ new Buffer v ]
    @_logsz = 0
    @_tot = @_sz = @_i = v.length
    @_no_push = true
    @

  #-----------------------------------------

  read_uint8 : () -> @_get @_cp++

  read_uint16 : () ->
    ret = @_frozen_buf.readUint16BE @_cp
    @_cp += 2
    return ret
  read_uint32 : () ->
    ret = @_frozen_buf.readUint32BE @_cp
    @_cp += 4
    return ret
  read_int16 : () ->
    ret = @_frozen_buf.readInt16BE @_cp
    @_cp += 2
    return ret
  read_int32 : () ->
    ret = @_frozen_buf.readInt32BE @_cp
    @_cp += 4
    return ret
  read_float64 : () ->
    ret = @_frozen_buf.readDoubleBE @_cp
    @_cp += 8
    return ret
  read_float32 : () ->
    ret = @_frozen_buf.readFloatBE @_cp
    @_cp += 4
    return ret
  read_byte_array : (n) ->
    e = @_cp + n
    ret = @_frozen_buf[@_cp...e]
    @_cp = e
    return ret
  read_utf8_string : (n) ->
    @read_byte_array(n).toString 'utf8'

  @utf8_to_ui8a   : (s) -> new Buffer s, 'utf8'
  @ui8a_to_binary : (s) -> s.toString 'binary'


