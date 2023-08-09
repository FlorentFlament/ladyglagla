all: hello.prg

hello.prg: hello.s picture-logo.s
	vc -vv -nostdlib +tos -o $@ $^

clean:
	rm -f *.prg *.tos
