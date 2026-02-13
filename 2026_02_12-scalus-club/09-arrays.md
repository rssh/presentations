# Array Builtins: O(1) Indexed Access (CIP-0156)

## The Problem

Plutus lists are linked lists -- accessing element N is O(N).
Transaction inputs, outputs, certificates are all lists.

## V4: Array Type

```
listToArray  : List a -> Array a       -- convert once
indexArray   : Array a -> Int -> a      -- O(1) access!
lengthOfArray : Array a -> Int
multiIndexArray : List Int -> Array a -> List a  -- batch access
```

## Use Case: Transaction Validation

```scala
// V3: O(N) to find the Nth input
val myInput = txInfo.inputs.drop(n).head

// V4: O(1) with arrays
val inputsArray = listToArray(txInfo.inputs)
val myInput = indexArray(inputsArray, n)
```

## When to Use

- Random access patterns on lists (skip to index)
- Multiple lookups from the same list
- Indexed UTxO pattern with known positions

## Where in Scalus

- Builtin definitions: `DefaultFun.scala:1283-1335`
- Cost model: `BuiltinCostModel.scala:128-131`
