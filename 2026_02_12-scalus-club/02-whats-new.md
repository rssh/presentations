# How Scala Constructs Compile Differently on PV11

## Case on Builtin Types (biggest impact)

In PV9, `Case` only works on `Data.Constr` values. PV11 extends it to primitives:

| Scala construct | PV9 UPLC | PV11 UPLC |
|------|-------------|-------------|
| **`match` on enum/ADT** | `equalsInteger` + `ifThenElse` chain | `Case(int, [branch0..N])` |
| **`if`/`else`, `&&`, `||`** | `ifThenElse` builtin | `Case(bool, [false, true])` |
| **Pair destructuring** | `fstPair`/`sndPair` builtins | `Case(pair, [λ(a,b).body])` |
| **`BuiltinList` match** | `chooseList`/`headList`/`tailList` | `Case(list, [λ(h,t).cons, nil])` |

**Case on Integer is the primary speedup driver.** Every enum/sealed trait match
and every `BigInt` pattern match benefits from O(1) dispatch.

## New Builtins

| Builtin | CIP | Purpose |
|---------|-----|---------|
| `dropList` | CIP-0158 | Drop first N elements from list |
| `indexArray`, `listToArray`, ... | CIP-0156 | O(1) array indexed access |
| `insertCoin`, `lookupCoin`, `unionValue`, ... | CIP-0153 | Native multi-asset value ops |
| `g1MultiScalarMul`, `g2MultiScalarMul` | CIP-0133 | BLS12-381 batch multiplication |

---

Source: `scalus-core/.../uplc/DefaultFun.scala:18-19` (builtin definitions)
