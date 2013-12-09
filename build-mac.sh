#!/bin/sh

ROOT=.
DMD=dmd
SD=${ROOT}/src
SRCS="${SD}/dlife/main.d ${SD}/sdl/bindings.d ${SD}/sdl/utils.d"
OD=${ROOT}/obj
OF=${ROOT}/life
INC=${SD}
OPTS="-od${OD} -of${OF} -I${INC} -unittest -L-framework -LSDL2" 

${DMD} ${SDLS} ${SRCS} ${OPTS}

