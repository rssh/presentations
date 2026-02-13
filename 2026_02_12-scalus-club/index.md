# Plutus V4: How P11 (Dijkstra) Speeds Up On-Chain Programs

## Slides

1. [Title & Headline Numbers](01-title.md)
2. [What's New in PlutusV4](02-whats-new.md)
3. [Case on Integer: The Biggest Win](03-case-on-integer.md) -- O(1) enum/ADT dispatch
4. [Case on Bool and Pair](04-case-on-bool-pair.md) -- secondary Case optimizations
5. [DropList: Faster Field Access](05-droplist.md) -- CIP-0158
6. [Benchmarks: Knights Problem](06-benchmarks.md) -- 8-case Direction enum, 25-36% CPU saved
7. [Benchmarks: Clausify SAT Solver](07-clausify.md) -- 6-case Formula enum, 49-54% CPU saved
8. [MaryEraValue: Native Multi-Asset Ops](08-maryera-value.md) -- CIP-0153
9. [Array Builtins: O(1) Indexed Access](09-arrays.md) -- CIP-0156
9a. [Modular Exponentiation: expModInteger](09a-expmod.md) -- CIP-0109, RSA/ZK on-chain
10. [How to Target PlutusV4 in Scalus](10-how-to-use.md) -- compiler options & VM setup
11. [High-Level PreimageValidator](11-highlevel-validator.md) -- baseline: full deserialization, prelude types
12. [Assembler Mode: Low-Level Control](12-assembler-mode.md) -- two levels: compiled builtins (Plutarch-style) & direct UPLC
13. [Compiled Assembler: Builtins in compile {}](13-assembler-dsl.md) -- ScottEncodingLowering, field macro, manual Data
14. [Same Validator with dropList](14-assembler-highlevel.md) -- SirToUplcV3Lowering, auto dropList
15. [Direct UPLC Construction: Term DSL](15-assembler-v4.md) -- build UPLC AST by hand with operators
16. [Source Code Map: V4 Lowering](16-source-map.md) -- Case on Bool/Pair/List, dropList, VM
17. [Source Code Map: Builtins & Examples](17-source-map-2.md) -- builtins, DSL, assembler, benchmarks
18. [Case on List: BuiltinList Pattern Match](18-case-on-list.md) -- V4 Case on List, BuiltinList.Cons/Nil
19. [Summary](19-summary.md) -- key takeaways & links

## Key Results (Scalus V3 UPLC vs V4 UPLC)

| Benchmark | V3 → V4 Memory Saved | V3 → V4 CPU Saved |
|-----------|----------------------|--------------------|
| Clausify F1 | **49%** | **53%** |
| Clausify F5 | **50%** | **54%** |
| Knights 4x4 | **29%** | **36%** |
| Knights 8x8 | **25%** | **33%** |

## How to Run

```bash
sbtn "scalusExamplesJVM/testOnly scalus.benchmarks.KnightsTest"
sbtn "scalusExamplesJVM/testOnly scalus.benchmarks.ClausifyTest"
```
