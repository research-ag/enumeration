MOPS_PKGS=$(shell mops sources)

all: enumeration

enumeration:
	moc $(MOPS_PKGS) -wasi-system-api lib.test.mo && wasmtime lib.test.wasm
