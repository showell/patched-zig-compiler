platform ""
	requires {
		make : U64 -> List(U8)
	}
	exposes []
	packages {}
	provides { "roc_make": make_for_host }
	targets: {
		x64musl: {
			inputs: [app],
			output: Archive,
		},
	}

make_for_host : U64 -> List(U8)
make_for_host = make
