<!-- _class: small -->

# Case on List: `BuiltinList` Pattern Match

In V4, `Case` on List destructures in **one dispatch** instead of separate `headList`/`tailList` calls.
With `@unchecked`, we omit the Nil branch -- VM throws `CaseListBranchError` automatically:

```scala
@Compile
object PreimageValidatorWithListMatch {
    import scalus.cardano.onchain.plutus.prelude.require
    def preimageValidator(datum: Data, redeemer: Data, ctxData: Data): Unit = {
        val pair = datum.toConstr.snd
        inline def hash = pair.head.toByteString
        val pkh = pair.tail.head
        inline def preimage = redeemer.toByteString
        def checkSignatories(sigs: BuiltinList[Data]): Unit =
            (sigs: @unchecked) match                   // V4: Case(list, [λ(h,t)=>...])
                case BuiltinList.Cons(h, t) =>         // single branch, no Nil needed
                    if h == pkh then () else checkSignatories(t)
        val txInfoFields = ctxData.toConstr.snd.head.toConstr.snd
        inline def sigs = dropList(BigInt(8), txInfoFields).head.toList
        checkSignatories(sigs)
        require(sha2_256(preimage) == hash)
    }
}
```

## Budget: PreimageValidator (5 variants)

| Variant | Flat | CPU | Mem | Fee |
|---------|------|-----|-----|-----|
| 1. Assembler + `field` macro (ScottEncoding, V3) | 443 B | 5,801,726 | 15,608 | 1,319 lovelace |
| **2. Assembler + `dropList` (V3Lowering, V4)** | **393 B** | **4,481,695** | **11,990** | **1,015 lovelace** |
| 3. High-level (V3Lowering, V3) | 513 B | 6,866,493 | 23,662 | 1,861 lovelace |
| 4. High-level (V3Lowering, V4) | 465 B | 5,093,782 | 19,110 | 1,470 lovelace |
| 5. Assembler + `dropList` + ListMatch (V4) | 393 B | 4,430,545 | 12,158 | 1,021 lovelace |

Source: `scalus-examples/.../PreimageBudgetComparisonTest.scala`
