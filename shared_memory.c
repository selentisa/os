// shared_memory.c

#include "shared_memory.h"
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>

sem_t *sem1, *sem2, *sem3, *sem4, *sem5, *sem6;
SharedData *shared_memory;

int clean(char *str)
{
    int len = 0;
    while (str[len] != '\0' && str[len] != '\n')
    {
        len++;
    }
    str[len] = '\0';
    return len;
}

void initialize_shared_memory()
{
    int shm_fd = shm_open("/my_shared_memory", O_CREAT | O_RDWR, 0666);
    if (shm_fd == -1)
    {
        perror("shm_open");
        exit(1);
    }

    if (ftruncate(shm_fd, SHARED_MEM_SIZE) == -1)
    {
        perror("ftruncate");
        exit(1);
    }

    shared_memory = (SharedData *)mmap(0, SHARED_MEM_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd, 0);
    if (shared_memory == MAP_FAILED)
    {
        perror("mmap");
        exit(1);
    }

    shared_memory->f = 1;
}

void initialize_semaphores()
{
    sem1 = sem_open("/my_semaphore1", O_CREAT, 0666, 0);
    if (sem1 == SEM_FAILED)
    {
        perror("sem_open");
        exit(1);
    }
    sem2 = sem_open("/my_semaphore2", O_CREAT, 0666, 0);
    if (sem2 == SEM_FAILED)
    {
        perror("sem_open");
        exit(1);
    }
    sem3 = sem_open("/my_semaphore3", O_CREAT, 0666, 0);
    if (sem3 == SEM_FAILED)
    {
        perror("sem_open");
        exit(1);
    }
    sem4 = sem_open("/my_semaphore4", O_CREAT, 0666, 0);
    if (sem4 == SEM_FAILED)
    {
        perror("sem_open");
        exit(1);
    }
    sem5 = sem_open("/my_semaphore5", O_CREAT, 0666, 0);
    if (sem5 == SEM_FAILED)
    {
        perror("sem_open");
        exit(1);
    }
    sem6 = sem_open("/my_semaphore6", O_CREAT, 0666, 0);
    if (sem6 == SEM_FAILED)
    {
        perror("sem_open");
        exit(1);
    }
}

void cleanup()
{
    if (munmap(shared_memory, SHARED_MEM_SIZE) == -1)
    {
        perror("munmap");
        exit(1);
    }

    if (sem_close(sem1) == -1)
    {
        perror("sem_close");
        exit(1);
    }
    if (sem_close(sem2) == -1)
    {
        perror("sem_close");
        exit(1);
    }
    if (sem_close(sem3) == -1)
    {
        perror("sem_close");
        exit(1);
    }
    if (sem_close(sem4) == -1)
    {
        perror("sem_close");
        exit(1);
    }
    if (sem_close(sem5) == -1)
    {
        perror("sem_close");
        exit(1);
    }
    if (sem_close(sem6) == -1)
    {
        perror("sem_close");
        exit(1);
    }

    if (sem_unlink("/my_semaphore1") == -1)
    {
        perror("sem_unlink");
        exit(1);
    }
    if (sem_unlink("/my_semaphore2") == -1)
    {
        perror("sem_unlink");
        exit(1);
    }
    if (sem_unlink("/my_semaphore3") == -1)
    {
        perror("sem_unlink");
        exit(1);
    }
    if (sem_unlink("/my_semaphore4") == -1)
    {
        perror("sem_unlink");
        exit(1);
    }
    if (sem_unlink("/my_semaphore5") == -1)
    {
        perror("sem_unlink");
        exit(1);
    }
    if (sem_unlink("/my_semaphore6") == -1)
    {
        perror("sem_unlink");
        exit(1);
    }
}
