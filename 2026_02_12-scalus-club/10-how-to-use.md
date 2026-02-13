# How to Target PlutusV4 in Scalus

## Compile Options

```scala
import scalus.compiler.{compile, Options}
import scalus.compiler.sir.TargetLoweringBackend
import scalus.cardano.ledger.Language

given Options = Options(
  targetLoweringBackend = TargetLoweringBackend.SirToUplcV3Lowering,
  targetLanguage = Language.PlutusV4,     // <-- target V4
  generateErrorTraces = true,
  optimizeUplc = true
)

val sir = compile { myValidator(args) }
val uplc = sir.toUplcOptimized(generateErrorTraces = false)
```

## Evaluation with V4 VM

```scala
import scalus.uplc.eval.PlutusVM

val vm = PlutusVM.makePlutusV4VM()
val result = vm.evaluateDebug(uplc)
println(s"Budget: ${result.budget}")  // ExUnits(memory, steps)
```

## What Happens Automatically

When `targetLanguage = PlutusV4`:
- `if/else` compiles to `Case` on Bool (not `ifThenElse`)
- Pair match compiles to `Case` on Pair (not `fstPair`/`sndPair`)
- Field access at index >= 2 uses `dropList` (not chained `tailList`)
- VM enables `caseOnBuiltinsEnabled = true`

No code changes needed -- just switch the target language.
