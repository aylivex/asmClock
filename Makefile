#   Make file for Clock.
#   Copyright (C) 1998 by Caravan of Love

#       make -B                 Will build Clock.exe
#       make -B -DDEBUG         Will build the debug version of Clock.exe

NAME = Clock
OBJS = $(NAME).obj
DEF  = $(NAME).def
RES  = $(NAME).res

!if $d(DEBUG)
TASMDEBUG=/zi
LINKDEBUG=/v
!else
TASMDEBUG=
LINKDEBUG=
!endif

IMPORT=Import32


$(NAME).EXE: $(OBJS) $(DEF) $(RES)
  TLink32 /Tpe /aa /c $(LINKDEBUG) $(OBJS),$(NAME),, $(IMPORT), $(DEF), $(RES)

.asm.obj:
   TAsm32 $(TASMDEBUG) /ml $&.asm

.rc.res:
   brcc32 $&.rc