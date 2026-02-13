# MaryEraValue: Native Multi-Asset Operations (CIP-0153)

## The Problem

In V1-V3, multi-asset values are encoded as nested Data maps:
```
Map [ (CurrencySymbol, Map [ (TokenName, Integer) ]) ]
```
Every `Value` operation requires repeated Data encoding/decoding.

## V4: Native `BuiltinValue` Type

New opaque type with dedicated builtins:

```
insertCoin  : BS -> BS -> Int -> Value -> Value
lookupCoin  : BS -> BS -> Value -> Int
unionValue  : Value -> Value -> Value
valueContains : Value -> Value -> Bool
scaleValue  : Int -> Value -> Value
valueData   : Value -> Data          -- convert to Data
unValueData : Data -> Value          -- convert from Data
```

## Benefits

- No repeated Data encoding/decoding per operation
- O(log n) lookups via sorted maps internally
- Automatic invariant maintenance (no zero quantities, sorted keys)
- Key validation (currency symbols <= 28 bytes, token names <= 32 bytes)

## Limitation

`ScriptContext` still uses V3 layout -- Value fields arrive as `Map[PolicyId, Map[AssetName, Int]]` (nested Data).
You need `unValueData`/`valueData` to convert. A new Plutus version with redesigned `ScriptContext`
would be needed to pass native Values directly.

## Where in Scalus

- Builtin definitions: `DefaultFun.scala:1337-1416`
- Implementation: `BuiltinValueOps.scala`
- Cost model: `BuiltinCostModel.scala:133-169`
- UPLC literal syntax: `(con value [#currSym { #tokenName : 100 }])`
