all: hello.prg

%.prg: %.s
	vasmm68k_mot -Ftos $< -o $@

clean:
	rm -f *.prg *.tos
