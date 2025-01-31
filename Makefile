# choose your compiler, e.g. gcc/clang
# example override to clang: make run CC=clang
CC = gcc

# Vector Engine compiler
NCC = /opt/nec/ve/bin/ncc
NCCFLAGS = -O3 -fopenmp -report-all -ffast-math -proginf 

# the most basic way of building that is most likely to work on most systems
.PHONY: run
run: run.c
	$(CC) -O3 -o run run.c -lm

.PHONY: runbf16
runbf16: runbf16.c
	$(CC) -O3 -o runbf16 runbf16.c -lm -fopenmp

# useful for a debug build, can then e.g. analyze with valgrind, example:
# $ valgrind --leak-check=full ./run out/model.bin -n 3
rundebug: run.c
	$(CC) -g -o run run.c -lm

# https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html
# https://simonbyrne.github.io/notes/fastmath/
# -Ofast enables all -O3 optimizations.
# Disregards strict standards compliance.
# It also enables optimizations that are not valid for all standard-compliant programs.
# It turns on -ffast-math, -fallow-store-data-races and the Fortran-specific
# -fstack-arrays, unless -fmax-stack-var-size is specified, and -fno-protect-parens.
# It turns off -fsemantic-interposition.
# In our specific application this is *probably* okay to use
.PHONY: runfast
runfast: run.c
	$(CC) -Ofast -o run run.c -lm

# additionally compiles with OpenMP, allowing multithreaded runs
# make sure to also enable multiple threads when running, e.g.:
# OMP_NUM_THREADS=4 ./run out/model.bin
.PHONY: runomp
runomp: run.c
	$(CC) -Ofast -fopenmp -march=native run.c  -lm  -o run

.PHONY: win64
win64:
	x86_64-w64-mingw32-gcc -Ofast -D_WIN32 -o run.exe -I. run.c win.c

# compiles with gnu99 standard flags for amazon linux, coreos, etc. compatibility
.PHONY: rungnu
rungnu:
	$(CC) -Ofast -std=gnu11 -o run run.c -lm

.PHONY: runompgnu
runompgnu:
	$(CC) -Ofast -fopenmp -std=gnu11 run.c  -lm  -o run

sgemv-intrinsics/sgemv_%.o:
	git clone https://github.com/efocht/sgemv-intrinsics.git

ve-runbf16: runbf16.c sgemv-intrinsics/sgemv_packed_bf16_unr.o
	$(NCC) $(NCCFLAGS) -march=ve1 -o $@ $^ -lm

ve-runbf16-cmo: runbf16.c sgemv-intrinsics/sgemv_bf16_cmo.o sgemv-intrinsics/sgemv_bf16_cmo_n.o
	$(NCC) $(NCCFLAGS) -march=ve1 -DCOLUMN_MEMORY_ORDER=1 -o $@ $^ -lm

ve-runbf16-ve3: runbf16.c sgemv-intrinsics/sgemv_bf16_ve3.o
	$(NCC) $(NCCFLAGS) -march=ve3 -mfp16-format=bfloat -o $@ $^ -lm

ve-runbf16-ve3-cmo: runbf16.c sgemv-intrinsics/sgemv_bf16_ve3_cmo.o
	$(NCC) $(NCCFLAGS) -march=ve3 -mfp16-format=bfloat -DCOLUMN_MEMORY_ORDER=1 -o $@ $^ -lm

# run all tests
.PHONY: test
test:
	pytest

# run only tests for run.c C implementation (is a bit faster if only C code changed)
.PHONY: testc
testc:
	pytest -k runc

# run the C tests, without touching pytest / python
# to increase verbosity level run e.g. as `make testcc VERBOSITY=1`
VERBOSITY ?= 0
.PHONY: testcc
testcc:
	$(CC) -DVERBOSITY=$(VERBOSITY) -O3 -o testc test.c -lm
	./testc

.PHONY: clean
clean:
	rm -f run
