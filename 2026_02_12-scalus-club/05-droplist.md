# DropList: Faster Field Access

## The Problem

Accessing field N of a case class requires skipping N list elements:

```
-- V3: chain of tailList calls
field_3 = headList(tailList(tailList(tailList(fields))))
```

Each `tailList` costs ~16K CPU. For field at index 5 that's 5 calls = ~80K CPU.

## V4: Single `dropList` Call

```
-- V4: one builtin call
field_3 = headList(dropList(3, fields))
```

## Savings Per Field Access

| Field index | V3 (chained tail) | V4 (dropList) | CPU saved |
|-------------|-------------------|---------------|-----------|
| 0 | headList | headList | 0 |
| 1 | tail + head | tail + head | 0 |
| 2 | 2x tail + head | dropList(2) + head | ~42K |
| 3 | 3x tail + head | dropList(3) + head | ~122K |
| 10 | 10x tail + head | dropList(10) + head | ~680K |

Scalus compiler uses `dropList` for index >= 2 when targeting V4.

## Where in Scalus

`ProductCaseSirTypeGenerator.scala:447-467` -- automatic optimization
