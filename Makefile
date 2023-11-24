all: main.prg

PlayerAky.o: PlayerAky.s
	vasmm68k_mot -nowarn=58 -align -spaces -noesc -no-opt -Faout -o $@ $<

music-data.o: music-data.s vorzugleetch.s
	vasmm68k_mot -nowarn=58 -align -spaces -noesc -no-opt -Faout -o $@ $<

main.prg: main.o animation.o picslib.o picsfx.o fx_stretch.o textwriter.o utils.o \
PlayerAky.o music-data.o \
picture-yogib33r-ladyglagla.o \
picture-callisto-ladyglagla.o \
picture-callisto-glafouk.o \
picture-logo.o \
VraiREglagla01-diff.o \
VRAI-REglagla02-diff.o \
VRAIglagla33-diff.o \
VRAI-REglagla04-diff.o
	vc -v -g -nostdlib +tos -o $@ $^

%.o: %.s
	vasmm68k_mot -Faout -o $@ $^

clean:
	rm -f *.prg *.tos *-fixed.s *.o

run: main.prg
	hatari --fast-boot true main.prg


# A few helpers

VraiREglagla01-diff.s:
	tools/png2data.py -b 2 gfx/glagla/glagla01/VraiREglagla01.0001.png > $@
	tools/png2data.py -b 2 -d gfx/glagla/glagla01/VraiREglagla01.0002.png \
		gfx/glagla/glagla01/VraiREglagla01.0001.png >> $@
	tools/png2data.py -b 2 -d gfx/glagla/glagla01/VraiREglagla01.0003.png \
		gfx/glagla/glagla01/VraiREglagla01.0001.png >> $@
	tools/png2data.py -b 2 -d gfx/glagla/glagla01/VraiREglagla01.0004.png \
		gfx/glagla/glagla01/VraiREglagla01.0001.png >> $@

VRAIglagla33-diff.s:
	tools/png2data.py -b 2 gfx/glagla/glagla03/VRAIglagla33.0001.png > $@
	tools/png2data.py -b 2 -d gfx/glagla/glagla03/VRAIglagla33.0002.png \
		gfx/glagla/glagla03/VRAIglagla33.0001.png >> $@
	tools/png2data.py -b 2 -d gfx/glagla/glagla03/VRAIglagla33.0003.png \
		gfx/glagla/glagla03/VRAIglagla33.0001.png >> $@
	tools/png2data.py -b 2 -d gfx/glagla/glagla03/VRAIglagla33.0004.png \
		gfx/glagla/glagla03/VRAIglagla33.0001.png >> $@

VRAI-REglagla04-diff.s:
	tools/png2data.py -b 2 gfx/glagla/glagla04/VRAI-REglagla04.0001.png > $@
	tools/png2data.py -b 2 -d gfx/glagla/glagla04/VRAI-REglagla04.0002.png \
		gfx/glagla/glagla04/VRAI-REglagla04.0001.png >> $@
	tools/png2data.py -b 2 -d gfx/glagla/glagla04/VRAI-REglagla04.0003.png \
		gfx/glagla/glagla04/VRAI-REglagla04.0001.png >> $@
	tools/png2data.py -b 2 -d gfx/glagla/glagla04/VRAI-REglagla04.0004.png \
		gfx/glagla/glagla04/VRAI-REglagla04.0001.png >> $@
	tools/png2data.py -b 2 -d gfx/glagla/glagla04/VRAI-REglagla04.0005.png \
		gfx/glagla/glagla04/VRAI-REglagla04.0001.png >> $@
