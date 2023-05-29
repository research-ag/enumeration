MOPS_PKGS=$(shell mops sources)

all: <package>

<package>:
	moc $(MOPS_PKGS) -wasi-system-api <package>.mo && wasmtime <package>.wasm

