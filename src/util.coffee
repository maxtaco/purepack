
##=======================================================================

exports.pow2 = pow2 = (n) -> if n < 31 then (1 << n) else Math.pow(2,n)
exports.U32MAX = U32MAX = pow2(32)
 
##=======================================================================

exports.rshift = (b, n) ->
  if n < 31 then (b >> n)
  else Math.floor(b / Math.pow(2,n))

##=======================================================================

exports.twos_compl = (x, n) -> if x < 0 then pow2(n) - Math.abs(x) else x
exports.twos_compl_inv = (x, n) -> x - pow2(n)

##=======================================================================
#
# The challenge is, given a positive integer i, to express
# 2^64 - i as per standard 2's complement, and then put both
# words in the buffer stream.  There's the way it's done:
#
#   Given input i>=0, pick x and y such that i = 2^32 x + y,
#   where x,y are both positive, and both less than 2^32.
#
#   Now we can write:
# 
#       2^64 - i = 2^64 - 2^32 x - y
#
#   Factoring and rearranging:
# 
#       2^64 - i = 2^32 * (2^32 - x - 1) + (2^32 - y)
# 
#   Thus, we've written:
#
#        2^64 - i =  2^32 a + b
#
#   Where 0 <= a,b < 2^32. In particular:
#
#       a = 2^32 - x - 1
#       b = 2^32 - y
#
#   And this satisfies our need to put two positive ints into
#   stream.
# 
exports.u64max_minus_i = (i) ->
  x = Math.floor( i / U32MAX)
  y = i & (U32MAX - 1)
  a = U32MAX - x - 1 # should be U32MAX - x - (if y > 0 then 1 else 0)
  b = U32MAX - y     # should be (if y is 0 then 0 else U32MAX - y)
  return [a, b]
