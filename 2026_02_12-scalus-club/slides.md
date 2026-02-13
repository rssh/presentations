---
marp: true
theme: default
paginate: true
style: |
  section {
    font-size: 21px;
  }
  h1 {
    font-size: 34px;
    color: #1a1a2e;
  }
  h2 {
    font-size: 26px;
    color: #16213e;
  }
  table {
    font-size: 17px;
  }
  code {
    font-size: 17px;
  }
  pre {
    font-size: 15px;
  }
  strong {
    color: #e94560;
  }
  section.small {
    font-size: 19px;
  }
  section.small table {
    font-size: 16px;
  }
  section.small pre {
    font-size: 14px;
  }
---

# P11 (van Rossem): How It Speeds Up On-Chain Programs

## What's Coming and When

**Protocol Version 11** -- intra-era hard fork (Conway stays), named **"van Rossem"**.
Community vote: Jan-Feb 2026. Mainnet: expected 2026 (node 10.7.0 candidate).

**Not Plutus V4** -- the Plutus ledger language API stays the same (V1/V2/V3).
New features are available across **all** existing Plutus versions.

## What's New in PV11

- **`Case` on builtin types** (Integer, Bool, Pair, List) -- O(1) dispatch
- **`dropList`** -- skip N list elements in one call (CIP-0158)
- **Array builtins** -- `indexArray`, `listToArray` for O(1) access (CIP-0156)
- **Native Value ops** -- `insertCoin`, `unionValue`, `lookupCoin` (CIP-0153)
- **BLS12-381 batch ops** -- `g1MultiScalarMul`, `g2MultiScalarMul` (CIP-0133)
- **`expModInteger`** -- modular exponentiation (CIP-0109)

---

# How Scala Constructs Compile Differently on PV11

In PV9, `Case` only works on `Data.Constr`. PV11 extends it to primitives:

| Scala construct | PV9 UPLC | PV11 UPLC |
|---------|-------------|-------------|
| **`match` on enum/ADT** | `equalsInteger` + `ifThenElse` chain | `Case(int, [branch0..N])` |
| **`if`/`else`, `&&`, `||`** | `ifThenElse` builtin | `Case(bool, [false, true])` |
| **Pair destructuring** | `fstPair` / `sndPair` | `Case(pair, [λ(a,b).body])` |
| **`BuiltinList` match** | `chooseList` / `headList` / `tailList` | `Case(list, [λ(h,t).cons, nil])` |
| **Case class field access** | chained `tailList` | `dropList(n, list)` -- CIP-0158 |
| **Indexed access** | n/a | `indexArray` O(1) -- CIP-0156 |
| **Value operations** | Data encoding | native `insertCoin`, `unionValue`, ... -- CIP-0153 |

**Case on Integer is the primary speedup driver** -- every enum/sealed trait
match and every `BigInt` pattern match benefits from O(1) dispatch.

---

# Case on Integer: The Biggest Win

## Scala source -- regular enums and pattern matching

```scala
enum Direction:                        // Knights benchmark
    case UL, UR, DL, DR, LU, LD, RU, RD

enum Formula:                          // Clausify benchmark
    case Sym(arg: Var)
    case Not(arg: Formula)
    case And(arg1: Formula, arg2: Formula)
    case Or(arg1: Formula, arg2: Formula)
    case Implication(arg1: Formula, arg2: Formula)
    case Equivalence(arg1: Formula, arg2: Formula)
```

Every `match` on these enums extracts constructor tag (integer) from `Data.Constr`.
PV9 generates **N-1 comparisons** -- O(N) dispatch. PV11: **O(1)**.

---

# Case on Integer: PV9 vs PV11 UPLC

## V3: chain of `equalsInteger` + `ifThenElse`

```
-- Direction (8 constructors) → 7 nested if-then-else
if (equalsInteger tag 0) then branchUL
else if (equalsInteger tag 1) then branchUR
else if (equalsInteger tag 2) then branchDL  ...  else branchRD
```

Each comparison: `equalsInteger` + `ifThenElse` + `force` = ~50K CPU

## PV11: single `Case` on Integer -- O(1) dispatch

```
Case(tag, [branchUL, branchUR, branchDL, branchDR, branchLU, branchLD, branchRU, branchRD])
```

Direct indexed jump. No comparisons, no branching chain.

---

## Enum / sealed trait match (tag from `Data.Constr`)

Every ADT match extracts the constructor tag (integer) from `Data.Constr`,
then dispatches on it. PV9: **N-1 comparisons**. PV11: **O(1) indexed jump**.

## `BigInt` literal pattern matching

```scala
x match
    case 0 => ...  // branch 0
    case 1 => ...  // branch 1
    case 2 => ...  // branch 2
```

PV9: chain of `equalsInteger` checks. PV11: `Case(x, [branch0, branch1, branch2])`.

## `Data` type matching

```scala
d match
    case Data.Constr(tag, args) => ...  // constructor
    case Data.Map(entries)      => ...  // map
    case Data.List(items)       => ...  // list
    case Data.I(value)          => ...  // integer
    case Data.B(bytes)          => ...  // bytestring
```

PV9: `chooseData` builtin (5-way). PV11: `Case` on Data tag -- O(1) dispatch.

---

# Case on Bool and Pair

## Case on Bool

Every `if/else`, `&&`, `||`, equality check is a boolean operation.

```
-- V3: ifThenElse builtin (requires force + apply chain)
(force (force ifThenElse) condition trueBranch falseBranch)

-- PV11: Case on Bool (direct dispatch, False=0, True=1)
(case condition falseBranch trueBranch)
```

In Clausify, bool operations are pervasive -- combined with Case on Integer
for Formula matching, this explains the **53% CPU drop**.

## Case on Pair

```
-- V3: two builtin calls with force
let fst = (force (force fstPair) pair)
let snd = (force (force sndPair) pair)

-- PV11: single Case, fields bound as lambda parameters
(case pair (λ fst snd → body))
```

---

# DropList: Faster Field Access

Case class fields are stored as a list in `Data.Constr`. Accessing field N means skipping N elements:

```scala
case class TxInfo(inputs: _, outputs: _, fee: _, mint: Value, ...)
//                  0         1        2      3 ← need to skip 3 fields
val mint = txInfo.mint   // compiles to: headList(tailList(tailList(tailList(fields))))
```

```
-- PV9: chain of tailList calls        -- PV11: one builtin call
field_3 = headList(                     field_3 = headList(
  tailList(tailList(tailList(fields)))    dropList(3, fields)
)                                       )
```

## Savings Per Field Access

| Field index | PV9 (chained tail) | PV11 (dropList) | CPU saved |
|-------------|-------------------|---------------|-----------|
| 0, 1 | same | same | 0 |
| 2 | 2x tail + head | dropList(2) + head | ~42K |
| 3 | 3x tail + head | dropList(3) + head | ~122K |
| 10 | 10x tail + head | dropList(10) + head | ~680K |

**`SirToUplcV3Lowering` backend** uses `dropList` automatically for index >= 2 when targeting PV11.
Just write `txInfo.mint` -- the compiler does the rest.

The `field` macro (assembler mode) still uses chained `tailList` --
it emits raw builtins directly, bypassing SIR lowering.

---

# Benchmark: Knights Problem

Knight's tour on a chess board -- heavy recursion, backtracking, list operations.

## PV9 vs PV11 (SirToUplcV3Lowering backend)

| Test | PV9 Memory | PV11 Memory | PV9 CPU | PV11 CPU | Mem Saved | CPU Saved |
|------|-----------|-----------|--------|--------|-----------|-----------|
| 4x4 | 324M | 229M | 92.3B | 59.3B | **29%** | **36%** |
| 6x6 | 822M | 611M | 228.3B | 152.0B | **26%** | **33%** |
| 8x8 | 1645M | 1234M | 452.9B | 302.9B | **25%** | **33%** |

Direction enum has 8 cases -- every move evaluation does a match.
PV9 needs up to 7 comparisons per match, PV11 does a single O(1) dispatch.

---

<!-- _class: small -->

# Benchmark: Clausify (SAT Solver)

Boolean-heavy computation: formula evaluation, CNF conversion.
Case on Integer (6-case Formula) + Case on Bool shine together.

## PV9 vs PV11 (SirToUplcV3Lowering backend)

| Test | PV9 Memory | PV11 Memory | PV9 CPU | PV11 CPU | Mem Saved | CPU Saved |
|------|-----------|-----------|--------|--------|-----------|-----------|
| F1 | 75M | 38M | 22.6B | 10.6B | **49%** | **53%** |
| F3 | 249M | 127M | 74.9B | 34.9B | **49%** | **53%** |
| F5 | 1206M | 608M | 363.3B | 166.7B | **50%** | **54%** |

Formula enum has 6 cases -- every formula transformation matches all 6.
PV9 needs up to 5 comparisons per match, PV11 does a single O(1) dispatch.
Combined with Case on Bool for pervasive boolean logic -- **53-54% CPU drop**.

---

# MaryEraValue: Native Multi-Asset Operations (CIP-0153)

In V1-V3, multi-asset values are encoded as nested Data maps.
Every `Value` operation requires repeated Data encoding/decoding.

## PV11: Native `BuiltinValue` Type

```
insertCoin  / lookupCoin    -- insert or lookup a single token quantity
unionValue  / valueContains -- combine values or check containment
scaleValue                  -- multiply all quantities
valueData   / unValueData   -- convert to/from Data
```

No repeated Data encoding/decoding, O(log n) lookups, automatic invariant maintenance.

## Limitation: ScriptContext is still V3

Value fields in `ScriptContext` still arrive as `Map[PolicyId, Map[AssetName, Int]]` (nested Data) --
you need `unValueData` to convert before using native ops.
A new Plutus version with redesigned `ScriptContext` would eliminate this overhead.

---

# Array Builtins: O(1) Indexed Access (CIP-0156)

```
listToArray     : List a -> Array a       -- convert once, CPU = 1K + 25K * len
indexArray      : Array a -> Int -> a     -- O(1), CPU = 232K constant
```

## dropList vs Array: CPU Cost Comparison

| Approach | Cost per access (index n, list length L) |
|----------|------------------------------------------|
| `dropList(n) + headList` | 200K + 2K * n |
| `listToArray(L) + indexArray` | (233K + 25K * L) once + 232K per access |

**Single access:** `dropList` wins -- no conversion overhead.
**Multiple accesses from same list:** array wins when `k > 1 + L/9` (roughly).
E.g. for L=10: array becomes cheaper at ~3 accesses.

## When to Use Arrays

- Multiple lookups from the same list (convert once, access many)
- Random access patterns where index is not sequential
- **Not worth it** for 1-2 accesses -- `dropList` is cheaper

---

# Modular Exponentiation: `expModInteger` (CIP-0109)

`expModInteger(base, exp, mod)` -- computes `base^exp mod mod` in one builtin call.
Supports negative exponents (modular inverse: `a^(-1) mod p`).

## What's Now Possible On-Chain

| Use case | Call |
|----------|------|
| **RSA-2048 signature verification** | `expModInteger(signature, 65537, n)` |
| **Finite field inverse** (`a^(-1) mod p`) | `expModInteger(a, -1, p)` |
| **Diffie-Hellman** (`g^x mod p`) | `expModInteger(g, x, p)` |
| **ZK proof verification** (BLS12-381 field ops) | field arithmetic with 381-bit primes |

```scala
// RSA signature verification -- one builtin call
val recovered = expModInteger(signature, BigInt(65537), rsaModulus)
require(recovered == expectedHash)
```

---

# How to Target PV11 in Scalus

```scala
import scalus.compiler.{compile, Options}
import scalus.compiler.sir.TargetLoweringBackend
import scalus.cardano.ledger.Language

given Options = Options(
  targetLoweringBackend = TargetLoweringBackend.SirToUplcV3Lowering,
  targetLanguage = Language.PlutusV4,     // <-- enables PV11 features
  generateErrorTraces = true,
  optimizeUplc = true
)

val sir = compile { myValidator(args) }
val uplc = sir.toUplcOptimized(generateErrorTraces = false)
```

## What Happens Automatically

When `targetLanguage = Language.PlutusV4` (PV11):
- Enum/ADT `match` compiles to `Case` on Integer (not if-else chain)
- `if/else` compiles to `Case` on Bool (not `ifThenElse`)
- Pair match compiles to `Case` on Pair (not `fstPair`/`sndPair`)
- Field access at index >= 2 uses `dropList` (not chained `tailList`)

**No code changes needed -- just switch the target language.**

---

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
| High-level (V3) | 513 B | 6,866,493 | 23,662 | 1,861 lovelace |
| High-level (PV11) | 465 B | 5,093,782 | 19,110 | 1,470 lovelace |

PV11 gives **26% CPU savings** with zero code changes. Can we do better with assembler mode?

Source: `scalus-examples/.../PreimageValidator.scala`

---

# Assembler Mode: Low-Level Control in Scalus

Beyond high-level Scala -- Scalus gives you **two levels of low-level control**,
similar to Plutarch in Haskell:

| | **High-Level** | **Compiled Assembler** | **Direct UPLC** |
|---|---|---|---|
| Write | Scala 3 with prelude types | Scala 3 with builtins & primitives | `Term` DSL |
| Goes through | compiler plugin | compiler plugin | you build UPLC directly |
| Types | `Value`, `TxInfo`, `List[A]` | `Data`, `ByteString`, `BuiltinList`, `BuiltinValue` | `Term`, `Constant`, `DefaultFun` |
| Control | automatic, high-level | **manual Data access, direct builtins** | full AST control |
| Analogy | Plutus Tx | -- | **Plutarch** (eDSL building UPLC) |

**Why assembler mode?**

- Skip unnecessary Data deserialization -- access only the fields you need
- Use builtins directly: `sha2_256`, `trace`, `unConstrData`, `equalsByteString`
- PV11 native ops: `insertCoin`, `unionValue`, `indexArray`, `dropList`
- Smaller scripts, lower CPU/memory costs

---

<!-- _class: small -->

# Compiled Assembler: Builtins in `compile {}`

Use `scalus.uplc.builtin.Builtins.*` and primitive types inside `compile {}` --
the compiler plugin maps them **directly to UPLC builtins**.

```scala
import scalus.uplc.builtin.Builtins.*
import scalus.uplc.builtin.{ByteString, Data, BuiltinList, BuiltinValue}
import scalus.cardano.onchain.plutus.prelude.require

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
        require(sha2_256(preimage) == hash)
    }
}
```

This style uses `ScottEncodingLowering` backend and the `field` macro for selective Data access.

Source: `scalus-examples/.../PreimageValidator.scala`

---

<!-- _class: small -->

# Same Validator with `dropList`

On PV11, replace the `field` macro with **`dropList`** directly -- same assembler style, fewer CPU steps:

```scala
@Compile
object OptimizedPreimageValidatorV4 {
    import scalus.cardano.onchain.plutus.prelude.require
    def preimageValidator(datum: Data, redeemer: Data, ctxData: Data): Unit = {
        val pair = datum.toConstr.snd
        inline def hash = pair.head.toByteString
        val pkh = pair.tail.head
        inline def preimage = redeemer.toByteString
        def checkSignatories(sigs: BuiltinList[Data]): Unit =
            if sigs.head == pkh then ()
            else checkSignatories(sigs.tail)
        val txInfoFields = ctxData.toConstr.snd.head.toConstr.snd   // ← CHANGED
        inline def sigs = dropList(                                  // ← CHANGED
            offsetOf[TxInfo](_.signatories), txInfoFields            // ← CHANGED
        ).head.toList                                                // ← CHANGED
        checkSignatories(sigs)
        require(sha2_256(preimage) == hash)
    }
}
```

| | Flat | CPU | Mem | Fee |
|-|------|-----|-----|-----|
| Baseline (`field` macro, V3) | 443 B | 5,801,726 | 15,608 | 1,319 lovelace |
| **`dropList` (PV11)** | **393 B** | **4,481,695** | **11,990** | **1,015 lovelace** |

---

<!-- _class: small -->

# Case on List: `BuiltinList` Pattern Match

In PV11, `Case` on List destructures in **one dispatch** instead of separate `headList`/`tailList` calls.
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
            (sigs: @unchecked) match                   // PV11: Case(list, [λ(h,t)=>...])
                case BuiltinList.Cons(h, t) =>         // single branch, no Nil needed
                    if h == pkh then () else checkSignatories(t)
        val txInfoFields = ctxData.toConstr.snd.head.toConstr.snd
        inline def sigs = dropList(offsetOf[TxInfo](_.signatories), txInfoFields).head.toList
        checkSignatories(sigs)
        require(sha2_256(preimage) == hash)
    }
}
```

| | Flat | CPU | Mem | Fee |
|-|------|-----|-----|-----|
| `dropList` only (PV11) | 393 B | 4,481,695 | 11,990 | 1,015 lovelace |
| **`dropList` + ListMatch (PV11)** | **393 B** | **4,430,545** | **12,158** | **1,021 lovelace** |

---

# Budget: PreimageValidator (5 variants)

| Variant | Flat | CPU | Mem | Fee |
|---------|------|-----|-----|-----|
| 1. Assembler + `field` macro (ScottEncoding, PV9) | 443 B | 5,801,726 | 15,608 | 1,319 lovelace |
| **2. Assembler + `dropList` (V3Lowering, PV11)** | **393 B** | **4,481,695** | **11,990** | **1,015 lovelace** |
| 3. High-level (V3Lowering, PV9) | 513 B | 6,866,493 | 23,662 | 1,861 lovelace |
| 4. High-level (V3Lowering, PV11) | 465 B | 5,093,782 | 19,110 | 1,470 lovelace |
| 5. Assembler + `dropList` + ListMatch (PV11) | 393 B | 4,430,545 | 12,158 | 1,021 lovelace |

Fee = execution cost only (mainnet prices: cpu=0.0000721, mem=0.0577 lovelace).

Assembler + dropList: **23% less CPU** than field macro, **35% less** than high-level PV9.

Source: `scalus-examples/.../PreimageBudgetComparisonTest.scala`

---

<!-- _class: small -->

# Direct UPLC Construction: Term DSL

For maximum control, build UPLC terms directly -- no compiler plugin needed:

```scala
import scalus.uplc.{Term, Constant => C}, Term.{asTerm, λ}, TermDSL.given, DefaultFun.*

def pfix(f: Term => Term): Term = λ { r => r $ r } $ λ { r => f(r $ r) }

val preimageValidator: Term = λ { datum => λ { redeemer => λ { ctxData =>
    (λ { pair =>                                    // let pair = snd(unConstr(datum))
        (λ { pkh =>                                 // let pkh = head(tail(pair))
            val txInfoFields = !(!SndPair) $ (UnConstrData $
                (!(HeadList) $ (!(!SndPair) $ (UnConstrData $ ctxData))))
            val sigs = UnListData $ (!(HeadList) $ (!(DropList) $ BigInt(8).asTerm $ txInfoFields))
            val checkSigs = pfix { recur => λ { s =>
                Term.Case(s, scala.List(                // Case on List: Cons-only
                    λ { h => λ { t =>                   // λhead.λtail.
                        Term.Case(EqualsData $ h $ pkh, // Case on Bool
                            scala.List(recur $ t, Term.Const(C.Unit)))
                    }}))
            }}
            (λ { _ =>                                   // sequence: checkSigs; then hash check
                Term.Case(EqualsByteString $ (Sha2_256 $ (UnBData $ redeemer))
                    $ (UnBData $ (!(HeadList) $ pair)),
                    scala.List(Term.Error, Term.Const(C.Unit)))
            }) $ (checkSigs $ sigs)
        }) $ (!(HeadList) $ (!(TailList) $ pair))
    }) $ (!(!SndPair) $ (UnConstrData $ datum))
}}}
```

Source: `scalus-examples/.../PreimageBudgetComparisonTest.scala`

---

# Budget: PreimageValidator (7 variants)

| Variant | Flat | CPU | Mem | Fee |
|---------|------|-----|-----|-----|
| 1. Assembler + `field` macro (ScottEncoding, PV9) | 443 B | 5,801,726 | 15,608 | 1,319 lovelace |
| 2. Assembler + `dropList` (V3Lowering, PV11) | 393 B | 4,481,695 | 11,990 | 1,015 lovelace |
| 3. High-level (V3Lowering, PV9) | 513 B | 6,866,493 | 23,662 | 1,861 lovelace |
| 4. High-level (V3Lowering, PV11) | 465 B | 5,093,782 | 19,110 | 1,470 lovelace |
| 5. Assembler + `dropList` + ListMatch (PV11) | 393 B | 4,430,545 | 12,158 | 1,021 lovelace |
| 6. Assembler + sigIndex in redeemer (PV11) | 387 B | 5,097,693 | 12,586 | 1,094 lovelace |
| **7. Direct UPLC (PV11)** | **353 B** | **4,014,545** | **9,558** | **841 lovelace** |

Fee = execution cost only (mainnet prices: cpu=0.0000721, mem=0.0577 lovelace). All variants without error traces.

Direct UPLC: **31% less CPU** than field macro, **42% less** than high-level PV9, **17% less fee** than best compiled variant.

Source: `scalus-examples/.../PreimageBudgetComparisonTest.scala`

---

<!-- _class: small -->

## Summary

| Optimization | Typical Savings |
|-------------|-----------------|
| Case on Integer | **25-54% CPU** -- O(1) enum/ADT dispatch |
| Case on Bool | Eliminates force+apply on every if/else |
| Case on Pair | Single dispatch vs two builtin calls |
| Case on List | Single dispatch vs `headList`/`tailList` |
| dropList | 42K-680K CPU per deep field access |
| Native Value ops | Eliminates Data encode/decode overhead |
| Array builtins | O(1) indexed access replaces O(N) traversal |

**Key Takeaway:** Switch `targetLanguage = Language.PlutusV4` (PV11) -- your existing code runs faster with **zero changes**.

**Assembler Mode:** For maximum performance, Scalus offers **three levels of control**:
- **High-level** -- idiomatic Scala, compiler handles everything
- **Compiled assembler** -- `Data`, `BuiltinList`, builtins directly inside `compile {}`
- **Direct UPLC** -- build `Term` values with the DSL, no compiler plugin needed

PreimageValidator fee: high-level PV11 **1,470**, compiled assembler **1,015**, direct UPLC **841** lovelace.
As we add more optimizations to the compiler, this gap will be eliminated.

**Links:** [Scalus](https://github.com/nau/scalus) | [CIP-0153](https://cips.cardano.org/cip/CIP-0153) | [CIP-0156](https://cips.cardano.org/cip/CIP-0156) | [CIP-0158](https://cips.cardano.org/cip/CIP-0158)
