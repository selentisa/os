#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <semaphore.h>
#include <string.h>
#include <pthread.h>

#define SHARED_MEM_SIZE 10240
#define SEM_NAME1 "/my_semaphore1"
#define SEM_NAME2 "/my_semaphore2"
#define SEM_NAME3 "/my_semaphore3"
#define SEM_NAME4 "/my_semaphore4"
#define SEM_NAME5 "/my_semaphore5"
#define SEM_NAME6 "/my_semaphore6"

typedef struct
{
    char mess1[4];
    int mess1_size;
    char mess2[4];
    int f;
    int mess2_size;

} SharedData;

sem_t *sem1, *sem2, *sem3, *sem4, *sem5, *sem6;
SharedData *shared_memory;

int custom_strlen(const char *str)
{
    int len = 0;
    while (str[len] != '\0' && str[len] != '\n')
    {
        len++;
    }
    return len;
}

void *send_message(void *arg)
{
    while (1)
    {

        char temp[256];

        fgets(temp, sizeof(temp), stdin);
        int size = custom_strlen(temp);
        shared_memory->mess1_size = size;
        // printf("size: %d\n", size);
        //  shared_memory->f = 1;

        sem_post(sem5);

        for (int i = 0; i <= (size)-1; i += 3)
        {

            strncpy(shared_memory->mess1, temp + i, 3);

            shared_memory->mess1[3] = '\0';
            // printf("mess1: %s\n", shared_memory->mess1);
            sem_post(sem1);

            sem_wait(sem3);
            // printf("finally! B posted sem3\n");
        }
        shared_memory->f = 0;

        if (strcmp(temp, "#BYE#") == 0)
        {

            return NULL;
        }

        // sem_wait(sem3);
    }
    return NULL;
}

void *receive_message(void *arg)
{
    while (1)
    {

        sem_wait(sem6);
        int size = shared_memory->mess2_size;
        char mess[256] = "";

        for (int i = 0; i <= size - 1; i += 3)
        {

            sem_wait(sem2);
            strcat(mess, shared_memory->mess2);
            sem_post(sem4);
        }

        printf("message by proc B: %s\n", mess);

        if (strcmp(shared_memory->mess1, "#BYE#") == 0)
        {
            printf("Terminating proc_b\n");

            return NULL;
        }
    }
    return NULL;
}

int main()
{
    int shm_fd;
    pthread_t send_thread, recv_thread;

    sem1 = sem_open(SEM_NAME1, O_CREAT, 0666, 0);
    sem2 = sem_open(SEM_NAME2, O_CREAT, 0666, 0);
    sem3 = sem_open(SEM_NAME3, O_CREAT, 0666, 0);
    sem4 = sem_open(SEM_NAME4, O_CREAT, 0666, 0);
    sem5 = sem_open(SEM_NAME5, O_CREAT, 0666, 0);
    sem6 = sem_open(SEM_NAME6, O_CREAT, 0666, 0);

    shm_fd = shm_open("/my_shared_memory", O_CREAT | O_RDWR, 0666);
    ftruncate(shm_fd, SHARED_MEM_SIZE);
    shared_memory = (SharedData *)mmap(0, SHARED_MEM_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd, 0);
    // shared_memory->atob = 0;

    pthread_create(&send_thread, NULL, send_message, NULL);
    pthread_create(&recv_thread, NULL, receive_message, NULL);

    pthread_join(send_thread, NULL);
    pthread_join(recv_thread, NULL);

    munmap(shared_memory, SHARED_MEM_SIZE);
    close(shm_fd);
    sem_close(sem1);
    sem_unlink(SEM_NAME1);
    sem_close(sem2);
    sem_unlink(SEM_NAME2);

    sem_close(sem3);
    sem_unlink(SEM_NAME3);
    sem_close(sem4);
    sem_unlink(SEM_NAME4);

    sem_close(sem5);
    sem_unlink(SEM_NAME5);

    sem_close(sem6);
    sem_unlink(SEM_NAME6);

    return 0;
}
