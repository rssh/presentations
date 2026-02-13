# Summary

## PlutusV4 Gives You Free Performance

| Optimization | What | Typical Savings |
|-------------|------|-----------------|
| Case on Integer | O(1) enum/ADT dispatch instead of if-else chain | 25-54% CPU (biggest win) |
| Case on Bool | Replaces `ifThenElse` builtin | Adds to the above on bool-heavy code |
| Case on Pair | Replaces `fstPair`/`sndPair` | Saves per-pair-match overhead |
| Case on List | Replaces `headList`/`tailList` | ~51K CPU per list match |
| dropList | Replaces chained `tailList` | 42K-680K CPU per field access |
| Native Value ops | Replaces Data encoding | Eliminates encode/decode overhead |
| Array builtins | O(1) indexed access | Replaces O(N) list traversal |

## Key Takeaway

Switch `targetLanguage = Language.PlutusV4` and your existing Scala code
runs faster with **zero code changes**.

The main win: every `match` on enum/sealed trait becomes O(1) dispatch
instead of a linear chain of integer comparisons.

## Links

- Scalus: https://github.com/nau/scalus
- CIP-0153: https://cips.cardano.org/cip/CIP-0153
- CIP-0156: https://cips.cardano.org/cip/CIP-0156
- CIP-0158: https://cips.cardano.org/cip/CIP-0158
- CIP-0133: https://cips.cardano.org/cip/CIP-0133
