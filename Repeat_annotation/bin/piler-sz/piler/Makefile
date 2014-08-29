CFLAGS = -O3 -funroll-loops -Winline -DNDEBUG=1
# LDLIBS = -lm -static
LDLIBS = -lm

OBJ = .o
EXE =

RM = rm -f
CP = cp

GPP = g++
LD = $(GPP) $(CFLAGS)
CPP = $(GPP) -c $(CFLAGS) 
CC = gcc -c $(CFLAGS) 

all: piler

CPPSRC = $(sort $(wildcard *.cpp))
CPPOBJ	= $(subst .cpp,.o,$(CPPSRC))

$(CPPOBJ): %.o: %.cpp
	$(CPP) $< -o $@

piler: $(CPPOBJ)
	$(LD) -o piler $(CPPOBJ) $(LDLIBS)
