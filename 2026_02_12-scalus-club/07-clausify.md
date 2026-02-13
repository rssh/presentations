# Benchmark Results: Clausify (SAT Solver)

Boolean-heavy computation: formula evaluation, CNF conversion.
This is where Case-on-Bool shines.

## Budget: V3 vs V4 (SirToUplcV3Lowering backend)

| Test | V3 Memory | V4 Memory | V3 CPU | V4 CPU | Mem Saved | CPU Saved |
|------|-----------|-----------|--------|--------|-----------|-----------|
| F1 | 75M | 38M | 22.6B | 10.6B | **49%** | **53%** |
| F2 | 93M | 48M | 28.0B | 13.2B | **48%** | **53%** |
| F3 | 249M | 127M | 74.9B | 34.9B | **49%** | **53%** |
| F4 | 345M | 181M | 100.7B | 46.3B | **48%** | **54%** |
| F5 | 1206M | 608M | 363.3B | 166.7B | **50%** | **54%** |

## Scalus V4 vs Haskell Plutus pre-V4 reference

| Test | Scalus V4 CPU | Haskell pre-V4 CPU | CPU ratio |
|------|---------------|---------------------|-----------|
| F1 | 10.6B | 12.3B | 0.86x |
| F3 | 34.9B | 41.9B | 0.83x |
| F5 | 166.7B | 203.2B | 0.82x |

Note: ref values are from Haskell Plutus **before V4**. A fair V4-to-V4
comparison requires re-running Haskell with V4 UPLC (TODO).

---

Source: `scalus-examples/.../benchmarks/ClausifyTest.scala`
