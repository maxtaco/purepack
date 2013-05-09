purepack
========

A pure CoffeeScript implemented of Msgpack.

We've made one addition to the spec.  When reserved byte `0xc4` prefaces
a raw string, the subsequent value is to be interepreted as raw bytes, and
not a UTF-8 string.

To force this behavior on the packing side, feed a Uint8Array to the packer
(instead of a regular string).  Uint8Arrays will automatically be returned
from unpacking.

## API

### purepack.pack(obj,opts)

Pack an object `obj`.  There are two options currently supported, off by default:

* `floats` --- Use floats rather than doubles when encoding.  Useful when saving space
* `byte_arrays` --- Encode Uint8Arrays differently from UTF-8 strings, using the `0xc4`
prefix described above.

