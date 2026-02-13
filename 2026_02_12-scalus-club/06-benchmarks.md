# Benchmark Results: Knights Problem

Knight's tour on a chess board -- heavy recursion, backtracking, list operations.

## Budget: V3 vs V4 (SirToUplcV3Lowering backend)

| Test | V3 Memory | V4 Memory | V3 CPU | V4 CPU | Mem Saved | CPU Saved |
|------|-----------|-----------|--------|--------|-----------|-----------|
| 4x4 | 324M | 229M | 92.3B | 59.3B | **29%** | **36%** |
| 6x6 | 822M | 611M | 228.3B | 152.0B | **26%** | **33%** |
| 8x8 | 1645M | 1234M | 452.9B | 302.9B | **25%** | **33%** |

## Scalus V4 vs Haskell Plutus pre-V4 reference

| Test | Scalus V4 CPU | Haskell pre-V4 CPU | CPU ratio |
|------|---------------|---------------------|-----------|
| 4x4 | 59.3B | 55.0B | 1.08x |
| 6x6 | 152.0B | 131.9B | 1.15x |
| 8x8 | 302.9B | 270.3B | 1.12x |

Note: Haskell Plutus compiled for V4 UPLC would also be faster (TODO: update).

---

Source: `scalus-examples/.../benchmarks/KnightsTest.scala`
