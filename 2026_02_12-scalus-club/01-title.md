# P11 (van Rossem): How It Speeds Up On-Chain Programs

## What's Coming and When

**Protocol Version 11** -- intra-era hard fork (Conway stays), named **"van Rossem"**.
Community vote: Jan-Feb 2026. Mainnet: expected 2026 (node 10.7.0 candidate).

**Not Plutus V4** -- the Plutus ledger language API stays the same (V1/V2/V3).
New features are available across **all** existing Plutus versions.

## What's New in PV11

- **`Case` on builtin types** (Integer, Bool, Pair, List) -- O(1) dispatch
- **`dropList`** -- skip N list elements in one call (CIP-0158)
- **Array builtins** -- `indexArray`, `listToArray` for O(1) access (CIP-0156)
- **Native Value ops** -- `insertCoin`, `unionValue`, `lookupCoin` (CIP-0153)
- **BLS12-381 batch ops** -- `g1MultiScalarMul`, `g2MultiScalarMul` (CIP-0133)
- **`expModInteger`** -- modular exponentiation (CIP-0109)
