all: main.prg

# TODO: Replace the vc that does everything by vasm per .s file
# Here are the flags required for the song file and maybe the player
# vasmm68k_mot -nowarn=58 -align -spaces -noesc -no-opt -Ftos example.s -o example.prg

PlayerAky.o: PlayerAky.s
	vasmm68k_mot -nowarn=58 -align -spaces -noesc -no-opt -Faout -o $@ $<

music-data.o: music-data.s vorzugleetch.s
	vasmm68k_mot -nowarn=58 -align -spaces -noesc -no-opt -Faout -o $@ $<

main.prg: main.o animation.o picslib.o picsfx.o textwriter.o utils.o \
PlayerAky.o music-data.o \
picture-callisto-glafouk.o \
VraiREglagla01-data.o \
VRAI-REglagla02-data.o \
picture-logo.o
	vc -v -g -nostdlib +tos -o $@ $^

%.o: %.s
	vasmm68k_mot -Faout -o $@ $^

clean:
	rm -f *.prg *.tos *-fixed.s *.o

run: main.prg
	hatari --fast-boot true main.prg
