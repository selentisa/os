
#ifndef SHARED_MEMORY_H
#define SHARED_MEMORY_H

#include <semaphore.h>
#include <time.h>
#include <unistd.h>
#include <string.h>

#define SHARED_MEM_SIZE 10240

typedef struct
{
    char mess1[15];
    int mess1_size;
    char mess2[15];
    int f;
    int mess2_size;
    time_t timestamp1, timestamp2, timestamp3, timestamp4;
} SharedData;

extern sem_t *sem1, *sem2, *sem3, *sem4, *sem5, *sem6;
extern SharedData *shared_memory;

void initialize_shared_memory();
void initialize_semaphores();
void cleanup();
int clean(char *str);

#endif
