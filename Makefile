CC = gcc
CFLAGS = -Wall -pthread
SHARED_FILES = shared_memory.c

all: proc_a proc_b

shared_memory.o: $(SHARED_FILES)
	$(CC) $(CFLAGS) -c $^

proc_a: proc_a.c shared_memory.o
	$(CC) $(CFLAGS) $^ -o $@

proc_b: proc_b.c shared_memory.o
	$(CC) $(CFLAGS) $^ -o $@

.PHONY: run_procs

run_procs:
	./run_procs.sh

clean:
	rm -f proc_a proc_b *.o
