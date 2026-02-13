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

## Why It Matters

Before PV11, modular exponentiation had to be implemented in Plutus by hand
(repeated squaring) -- **infeasible for real key sizes** (2048+ bits).
Modular inverse had to be computed **off-chain** and passed as tx argument,
increasing transaction size and shifting trust assumptions.

```scala
// RSA signature verification in one line
val recovered = expModInteger(signature, BigInt(65537), rsaModulus)
require(recovered == expectedHash)
```

---

Source: [CIP-0109](https://cips.cardano.org/cip/CIP-0109)
Builtin definition: `scalus-core/.../uplc/DefaultFun.scala:1232-1261`
