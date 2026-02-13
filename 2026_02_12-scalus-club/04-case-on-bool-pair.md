# Case on Bool and Pair

## Case on Bool

Every `if/else`, `&&`, `||`, equality check in your contract is a boolean operation.

```
-- V3: ifThenElse builtin (requires force + apply chain)
(force (force ifThenElse) condition trueBranch falseBranch)

-- V4: Case on Bool (direct dispatch, False=0, True=1)
(case condition falseBranch trueBranch)
```

In Clausify, bool operations are pervasive -- formula evaluation, CNF
conversion, clause manipulation all use boolean logic heavily.
Combined with Case on Integer for Formula matching, this explains the 53% CPU drop.

## Case on Pair

Tuple/pair destructuring is common when working with lists of pairs (e.g. maps, associations).

```
-- V3: two builtin calls with force
let fst = (force (force fstPair) pair)
let snd = (force (force sndPair) pair)

-- V4: single Case, fields bound as lambda parameters
(case pair (λ fst snd → body))
```

## Where in Scalus

- Case on Bool: `LoweredValue.scala:1001-1042`, `PrimitiveSirTypeGenerators.scala:267`
- Case on Pair: `ProductCaseSirTypeGenerator.scala:232-266`, `:697-716`
- VM: `Cek.scala:828-840` (Bool), `Cek.scala:940` (Pair)
