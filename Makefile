all: hello.prg

hello.prg: hello.s picture-logo.s
	vc -vv -g -O=0 -nostdlib +tos -o $@ $^

clean:
	rm -f *.prg *.tos
