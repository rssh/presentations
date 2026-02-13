# Assembler Mode: Low-Level Control in Scalus

Beyond high-level Scala -- Scalus gives you **two levels of low-level control**,
similar to Plutarch in Haskell:

| | **High-Level** | **Compiled Assembler** | **Direct UPLC** |
|---|---|---|---|
| Write | Scala 3 with prelude types | Scala 3 with builtins & primitives | `Term` DSL |
| Goes through | compiler plugin → SIR → UPLC | compiler plugin → SIR → UPLC | you build UPLC directly |
| Types | `Value`, `TxInfo`, `List[A]` | `Data`, `ByteString`, `BuiltinList`, `BuiltinValue` | `Term`, `Constant`, `DefaultFun` |
| Control | automatic, high-level | **manual Data access, direct builtins** | full AST control |
| Analogy | Plutus Tx | -- | **Plutarch** (eDSL building UPLC) |

**Why assembler mode?**

- Skip unnecessary Data deserialization -- access only the fields you need
- Use builtins directly: `sha2_256`, `trace`, `unConstrData`, `equalsByteString`
- V4 native ops: `insertCoin`, `unionValue`, `indexArray`, `dropList`
- Smaller scripts, lower CPU/memory costs
