<!-- _class: small -->

# Compiled Assembler: Builtins in `compile {}`

Use `scalus.uplc.builtin.Builtins.*` and primitive types inside `compile {}` --
the compiler plugin maps them **directly to UPLC builtins**.

```scala
import scalus.uplc.builtin.Builtins.*
import scalus.uplc.builtin.{ByteString, Data, BuiltinList, BuiltinValue}

@Compile
object OptimizedPreimageValidator {
    def preimageValidator(datum: Data, redeemer: Data, ctxData: Data): Unit = {
        // Manual Data deconstruction -- no full deserialization
        val pair = datum.toConstr.snd
        inline def hash = pair.head.toByteString
        val pkh = pair.tail.head
        inline def preimage = redeemer.toByteString
        // Walk signatories list with BuiltinList[Data]
        def checkSignatories(sigs: BuiltinList[Data]): Unit =
            if sigs.head == pkh then ()
            else checkSignatories(sigs.tail)
        // Direct field access -- skip unused TxInfo fields
        inline def sigs = ctxData.field[ScriptContext](_.txInfo.signatories).toList
        checkSignatories(sigs)
        sha2_256(preimage) == hash || (throw new RuntimeException("Wrong"))
    }
}
```

**Available builtins:** `sha2_256`, `blake2b_256`, `verifyEd25519Signature`,
`trace`, `equalsByteString`, `addInteger`, `unConstrData`, `unListData`,
`insertCoin`, `lookupCoin`, `unionValue`, `indexArray`, `dropList`, ...

Source: `scalus-examples/.../PreimageValidator.scala`, `PubKeyValidator.scala`
