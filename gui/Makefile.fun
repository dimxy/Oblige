#----------------------------------------------------------------
# Oblige
#----------------------------------------------------------------
#
# GNU Makefile for Unix/Linux "fun in the sun" version
#

PROGRAM=../Oblige

CXX=g++

LIB_LOC=/home/aapted/other

FLTK_DIR=$(LIB_LOC)/fltk-1.1.x-r5479
LUA_DIR=$(LIB_LOC)/lua-5.1
GLBSP_DIR=$(LIB_LOC)/glbsp-2.20

# operating system choices: UNIX WIN32
OS=UNIX


#--- Internal stuff from here -----------------------------------

FLTK_FLAGS=-I$(FLTK_DIR)
FLTK_LIBS=$(FLTK_DIR)/lib/libfltk_images.a \
          $(FLTK_DIR)/lib/libfltk.a \
          -lX11 -lXext -lpng -ljpeg

LUA_FLAGS=-I$(LUA_DIR)/src
LUA_LIBS=$(LUA_DIR)/src/liblua.a

GLBSP_FLAGS=-I$(GLBSP_DIR)
GLBSP_LIBS=$(GLBSP_DIR)/libglbsp.a

CXXFLAGS=-O -g -Wall -D$(OS) \
         $(FLTK_FLAGS) $(LUA_FLAGS) $(GLBSP_FLAGS)
LDFLAGS=-L/usr/X11R6/lib 
LIBS=-lm -lz $(FLTK_LIBS) $(LUA_LIBS) $(GLBSP_LIBS)

OBJS=	main.o      \
	lib_argv.o  \
	lib_util.o  \
	sys_assert.o \
	sys_debug.o \
	g_cookie.o  \
	g_doom.o    \
	g_glbsp.o   \
	g_image.o   \
	g_lua.o     \
	g_wolf.o    \
	twister.o   \
	ui_adjust.o  \
	ui_build.o  \
	ui_chooser.o \
	ui_dialog.o \
	ui_menu.o   \
	ui_setup.o  \
	ui_window.o


#--- Targets and Rules ------------------------------------------

all: $(PROGRAM)

clean:
	rm -f $(PROGRAM) *.o core core.*
	rm -f ob_debug.txt ERRS update.log

$(PROGRAM): $(OBJS)
	$(CXX) $(CFLAGS) $(OBJS) -o $@ $(LDFLAGS) $(LIBS)

g_image.o: img_data.h

bin: all
	strip --strip-unneeded $(PROGRAM)

.PHONY: all clean bin

#--- editor settings ------------
# vi:ts=8:sw=8:noexpandtab
