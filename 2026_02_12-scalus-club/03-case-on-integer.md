# Case on Integer: The Biggest Win

## The Problem: Enum/ADT Matching in V3

Every `match` on a sealed trait / enum is compiled to:
1. Extract constructor tag (integer) from `Data.Constr`
2. Chain of `if (equalsInteger(tag, 0)) then ... else if (equalsInteger(tag, 1)) then ...`

For an enum with N constructors, V3 generates **N-1 comparisons** -- O(N) dispatch.

```
-- V3: Direction (8 constructors) → 7 nested if-then-else
if (equalsInteger tag 0) then branchUL
else if (equalsInteger tag 1) then branchUR
else if (equalsInteger tag 2) then branchDL
...
else branchRD
```

Each comparison: `equalsInteger` + `ifThenElse` + `force` = ~50K CPU

## V4: Single `Case` on Integer

```
-- V4: O(1) dispatch
Case(tag, [branchUL, branchUR, branchDL, branchDR, branchLU, branchLD, branchRU, branchRD])
```

Direct indexed jump. No comparisons, no branching chain.

## Why This Dominates the Benchmarks

**Knights** -- `Direction` enum has **8 cases** (UL, UR, DL, DR, LU, LD, RU, RD).
Every move evaluation matches on direction. V3 needs up to 7 comparisons per match.
With V4 Case on Integer: **single O(1) dispatch**.

**Clausify** -- `Formula` enum has **6 cases** (Sym, Not, And, Or, Implication, Equivalence).
Every formula transformation (eliminate, negateCNF, flatten, split, unicl) matches all 6.
V3 needs up to 5 comparisons per match.

This is the same mechanism that handles `match` on `BigInt` literal patterns:

```scala
x match
    case 0 => ...  // branch 0
    case 1 => ...  // branch 1
    case 2 => ...  // branch 2
```

V3: chain of `equalsInteger` checks. V4: `Case(x, [branch0, branch1, branch2])`.

## Where in Scalus

- ADT/enum matching: `SumCaseSirTypeGenerator.scala:380-385`
  - V3 path (if-else chain): `SumCaseSirTypeGenerator.scala:407-429`
- Integer literal matching: `BaseSimpleLowering.scala:365-416`
  - V3 path (equalsInteger chain): `BaseSimpleLowering.scala:420-434`
- `CaseIntegerLoweredValue`: `LoweredValue.scala:1044-1084`
- VM dispatch: `Cek.scala:830-831` -- `Case` on `Constant.Integer`
