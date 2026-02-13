<!-- _class: small -->

# High-Level PreimageValidator

Standard Scalus style -- full Data deserialization, prelude types, `.find`:

```scala
@Compile
object PreimageValidator {
    def preimageValidator(datum: Data, redeemer: Data, ctxData: Data): Unit = {
        val (hash, pkh) = datum.to[(ByteString, ByteString)]
        val preimage = redeemer.toByteString
        val ctx = ctxData.to[ScriptContext]
        ctx.txInfo.signatories.find(_.hash == pkh).orFail("Not signed")
        require(sha2_256(preimage) == hash, "Wrong preimage")
    }
}
```

Clean and readable -- but deserializes **all** of `ScriptContext` including unused fields.

| | Flat | CPU | Mem | Fee |
|-|------|-----|-----|-----|
| High-level (V3) | 554 B | 6,914,493 | 23,962 | 1,882 lovelace |
| High-level (V4) | 507 B | 5,141,782 | 19,410 | 1,491 lovelace |

V4 gives **26% CPU savings** with zero code changes. Can we do better with assembler mode?

Source: `scalus-examples/.../PreimageValidator.scala`
