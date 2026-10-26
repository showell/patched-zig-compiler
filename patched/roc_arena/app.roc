app [make] { pf: platform "./platform/main.roc" }

## A small list, then a large one: the large one doesn't fit the arena's
## first node, so the host's arena grows.
make : U64 -> List(U8)
make = |n| {
	small = List.repeat(1, 100)
	big = List.repeat(2, n)
	big.concat(small)
}
