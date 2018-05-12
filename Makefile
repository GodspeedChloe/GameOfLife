#
# Makefile for Game of life
# Author:	Chloe Jackson
#

#
# Location of the processing programs
#
RASM 	= /home/fac/wrc/bin/rasm
RLINK 	= /home/fac/wrc/bin/rlink
RSIM	= /home/fac/wrc/bin/rsim

#
# Suffixes to be used or created
#
.SUFFIXES:	.asm .obj .lst .out

#
# Transformation rule: .asm into .obj
#
.asm.obj:
	$(RASM) -l $*.asm > $*.lst

#
# Transformation rule:	.obj into .out
#
.obj.out:
	$(RLINK) -m -o $*.out $*.obj >$*.map

#
# Main target
#
gameoflife.out:	gameoflife.obj


run:	gameoflife.obj
	- $(RSIM) gameoflife.out

debug:	gameoflife.obj
	- $(RSIM) -d gameoflife.out

clean:
	rm *.obj *.lst *.out
