#!/usr/bin/env bash


if true
then

/opt/nec/ve/bin/ncc \
	-report-all \
	-O4 \
	-ffast-math \
	-msched-block \
	-fopenmp \
    -proginf \
	-o run \
	run.c \
	-lm \
	-lcblas \
	-lblas_openmp

    #-mparallel \
    #-ftrace \
	#-finline-functions \
	#-finline-max-depth=20 \
	#-lblas_openmp
	#-lblas_sequential


else

/opt/nec/ve/bin/ncc \
	-O4 \
	-finline-functions \
	-finline-max-depth=20 \
	-ffast-math \
	-msched-block \
    -o run \
	run.c \
	-lm
fi
#    -mparallel \


#gcc -Ofast -ffast-math -fopenmp -o run run.c -lm
