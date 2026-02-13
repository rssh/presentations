<!-- _class: small -->

# Source Code Map: V4 Lowering

| Feature | Key File | Lines |
|---------|----------|-------|
| Language enum (V4) | `scalus-core/.../ledger/Types.scala` | 23-26 |
| V4 builtins | `scalus-core/.../uplc/DefaultFun.scala` | 18-19, 1263-1416 |
| Case on Bool | `scalus-core/.../lowering/LoweredValue.scala` | 1001-1050, 1410 |
| Case on Pair | `scalus-core/.../typegens/ProductCaseSirTypeGenerator.scala` | 232-266, 697-716 |
| Case on List | `scalus-core/.../typegens/SumListCommonSirTypeGenerator.scala` | 466-560 |
| dropList optimization | `scalus-core/.../typegens/ProductCaseSirTypeGenerator.scala` | 447-467 |
| VM: Case on builtins | `scalus-core/.../uplc/eval/Cek.scala` | 719, 833-840 |
| PlutusV4 VM factory | `scalus-core/.../uplc/eval/PlutusVM.scala` | 37 |
| V4 cost models | `scalus-core/.../uplc/eval/BuiltinCostModel.scala` | 126-169 |
