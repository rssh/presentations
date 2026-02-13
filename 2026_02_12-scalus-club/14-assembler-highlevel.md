<!-- _class: small -->

# Same Validator with `dropList`

On V4, replace the `field` macro with **`dropList`** directly -- same assembler style, fewer CPU steps:

```scala
@Compile
object OptimizedPreimageValidatorV4 {
    def preimageValidator(datum: Data, redeemer: Data, ctxData: Data): Unit = {
        val pair = datum.toConstr.snd
        inline def hash = pair.head.toByteString
        val pkh = pair.tail.head
        inline def preimage = redeemer.toByteString
        def checkSignatories(sigs: BuiltinList[Data]): Unit =
            if sigs.head == pkh then ()
            else checkSignatories(sigs.tail)
        val txInfoFields = ctxData.toConstr.snd.head.toConstr.snd  // V4: dropList
        inline def sigs = dropList(BigInt(8), txInfoFields).head.toList
        checkSignatories(sigs)
        sha2_256(preimage) == hash || (throw new RuntimeException("Wrong"))
    }
}
```

| Variant | Flat | CPU | Mem |
|---------|------|-----|-----|
| 1. Assembler + `field` macro (ScottEncoding, V3) | 455 B | 5,801,726 | 15,608 |
| **2. Assembler + `dropList` (V3Lowering, V4)** | **410 B** | **4,577,695** | **12,590** |
| 3. High-level (V3Lowering, V3) | 554 B | 6,914,493 | 23,962 |
| 4. High-level (V3Lowering, V4) | 507 B | 5,141,782 | 19,410 |
