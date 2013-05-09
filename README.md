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

### purepack.pack(obj,encoding,opts)

Pack an object `obj`.

#### encoding

After packing, output the result according to the given encoding.  Encodings include

* `buffer` --- Output as a `buffer.Buffer` on node, or a `Uint8Array` buffer in a browser
* `base64` --- Output as a standard base64-encoded string (with `+` and `/` outputs at positions 62 and 63)
* `base64a` --- Output as base64-encoding, with `@` and `_` characters rather than
the `+` and `/` characters.  Better for URLs.
* `base64x` --- Output as base64-encoding, with `+` and `-` characters rather than
the `+` and `/` characters.  Better for filenames.
* `base32` --- (sfs)[https://github.com/okws/sfslite]-style base32-encoding
* `hex` --- Standard base16/hex encoding
* `binary` --- Output as a binary string. Beware, UTF-8 problems ahead!
* `ui8a` --- Synonym for `buffer` on the browser, or output to a `Uint8Array` on node.

#### opts

There are two options currently supported, off by default:

* `floats` --- Use floats rather than doubles when encoding.  Useful when saving space
* `byte_arrays` --- Encode Uint8Arrays differently from UTF-8 strings, using the `0xc4`
prefix described above.

