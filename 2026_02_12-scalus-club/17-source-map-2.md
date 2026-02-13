<!-- _class: small -->

# Source Code Map: Builtins, DSL & Examples

| Feature | Key File | Lines |
|---------|----------|-------|
| MaryEraValue ops | `scalus-core/.../uplc/eval/BuiltinValueOps.scala` | 1-200+ |
| Builtin functions | `scalus-core/.../uplc/builtin/Builtins.scala` | 33-1480+ |
| Term DSL | `scalus-core/.../uplc/Term.scala`, `TermDSL.scala` | 24-43 |
| Compiled assembler | `scalus-examples/.../PreimageValidator.scala` | 48-70 |
| BuiltinList match | `scalus-examples/.../PreimageBudgetComparisonTest.scala` | 39-56 |
| Direct UPLC example | `scalus-examples/.../FactorialTest.scala` | 23-36 |

## Benchmarks

| Benchmark | File |
|-----------|------|
| Knights tour | `scalus-examples/.../benchmarks/KnightsTest.scala` |
| Clausify SAT | `scalus-examples/.../benchmarks/ClausifyTest.scala` |
| Budget comparison | `scalus-examples/.../PreimageBudgetComparisonTest.scala` |

```bash
sbtn "scalusExamplesJVM/testOnly scalus.benchmarks.KnightsTest"
sbtn "scalusExamplesJVM/testOnly scalus.benchmarks.ClausifyTest"
sbtn "scalusExamplesJVM/testOnly scalus.examples.PreimageBudgetComparisonTest"
```
