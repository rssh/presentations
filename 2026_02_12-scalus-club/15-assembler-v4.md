<!-- _class: small -->

# Direct UPLC Construction: Term DSL

For maximum control, build UPLC terms directly using Scala data types:

```scala
import scalus.uplc.Term, scalus.uplc.Term.*, scalus.uplc.TermDSL.given
import scalus.uplc.DefaultFun.*
import scala.language.implicitConversions

// Factorial -- direct UPLC construction (no compiler plugin)
val factorial = {
    val fix = λ { r => r $ r } $ λ { r => λ("f")(vr"f" $ (r $ r)) }
    fix $ λ { recur =>
        λ("n")(
            !(!IfThenElse $ (LessThanEqualsInteger $ vr"n" $ 0)
                $ ~1.asTerm
                $ ~(MultiplyInteger $ vr"n" $ (recur $ (SubtractInteger $ vr"n" $ 1))))
        )
    }
}
```

## DSL Cheat Sheet

| Scala | UPLC | |
|-------|------|-|
| `f $ x` | `Apply(f, x)` | function application |
| `!t` / `~t` | `Force(t)` / `Delay(t)` | force / delay |
| `λ("x")(body)` | `LamAbs("x", body)` | lambda abstraction |
| `λ { x => x $ x }` | `LamAbs("x", Apply(x, x))` | lambda macro |
| `42.asTerm` | `Const(Integer(42))` | auto-lift Scala value |
| `AddInteger` | `Builtin(AddInteger)` | implicit conversion for 100+ builtins |
| `Term.Case(...)` | `Case(arg, branches)` | V4 O(1) dispatch |

**All V4 builtins available:** `InsertCoin`, `UnionValue`, `IndexArray`, `DropList`, ...

Source: `scalus-core/.../uplc/Term.scala`, `TermDSL.scala`, `scalus-examples/.../FactorialTest.scala`
