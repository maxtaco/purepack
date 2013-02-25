
BaseBuffer = require('./base').Buffer

##=======================================================================

exports.Buffer = class NodeBuffer extends BaseBuffer

  #-----------------------------------------

  constructor : () ->
    super()
    @_buffers = []
    @_limits = []
    @_sz = 0x1000
    @_logsz = 12
    @_i = 0
    @_no_push = false
    @_tot = 0
    @_push_new_buffer()

  #-----------------------------------------

  @decode = (s, enc) -> BaseBuffer._decode NodeBuffer, s, enc

  #-----------------------------------------

  _nb  : () -> @_buffers.length     # num buffers
  _ab  : () -> @_buffers[@_nb()]    # active buffer
  _lib : () -> @_sz - @_i           # left in buffer

  #-----------------------------------------

  _push_buffer : (b) ->
    @_limits[@_nb()] = @_i
    @_i = 0
    @_buffers.push b
    b

  #-----------------------------------------

  _push_new_buffer : () -> @_push_buffer new Buffer @_sz

  #-----------------------------------------
  
  _push_byte : (b) ->
    throw new Error "Cannot push anymore into this buffer" if @_no_push
    buf = if @_lib() is 0 then @_push_new_buffer() else @_ab()
    buf[@_i++] = @_b
    @_tot++

  push_short : (s) -> 
    n = 2
    if @_lib() < n then @_push_new_buffer()
    @_ab().writeUint16BE s, @_i
    @_i += n
    @_tot += n

  push_int : (i) ->
    n = 4
    if @_lib() < n then @_push_new_buffer()
    @_ab().writeUint32BE s, @_i
    @_i += n
    @_tot += n
