
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include "shared_memory.h"

int counter_messages_recv, counter_messages_send, counter_packages;
double time_sum;

void *send_message(void *arg)
{
    while (shared_memory->f)
    {

        char temp[256];

        fgets(temp, sizeof(temp), stdin);
        int size = clean(temp);
        shared_memory->mess1_size = size;
        // printf("size: %d\n", size);
        //  shared_memory->f = 1;
        shared_memory->timestamp1 = time(NULL);
        sem_post(sem5);

        for (int i = 0; i <= (size); i += 15)
        {

            strncpy(shared_memory->mess1, temp + i, 15);

            // shared_memory->mess1[3] = '\0';
            //  printf("mess1: %s\n", shared_memory->mess1);
            sem_post(sem1);

            sem_wait(sem3);
            // printf("finally! B posted sem3\n");
        }
        // shared_memory->f = 0;
        counter_messages_send++;
        if (strcmp(temp, "#BYE#") == 0)
        {
            printf("Process A is going to terminate\n");
            // sem_post(sem5);
            shared_memory->f = 0;
            counter_messages_recv--;
            counter_packages--;
            // pthread_cancel(*(pthread_t *)arg);
        }

        // sem_wait(sem3);
    }
    return NULL;
}

void *receive_message(void *arg)
{
    while (shared_memory->f)
    {

        sem_wait(sem6);
        int size = shared_memory->mess2_size;
        char mess[256] = "";

        for (int i = 0; i <= size; i += 15)
        {

            sem_wait(sem2);
            if (i == 0)
            {
                shared_memory->timestamp4 = time(NULL);
                time_sum += difftime(shared_memory->timestamp2, shared_memory->timestamp4);
            }
            strcat(mess, shared_memory->mess2);
            counter_packages++;
            sem_post(sem4);
        }

        printf("\033[0;31mB: %s\n\033[0m\n", mess);
        // printf("message by proc B: %s\n", mess);
        counter_messages_recv++;
        if (strcmp(mess, "#BYE#") == 0)
        {
            printf("Press Enter to terminate\n");
            shared_memory->f = 0;
            counter_messages_send--;
            break;
        }
        // counter_messages_recv++;
    }
    return NULL;
}

int main()
{
    initialize_shared_memory();
    initialize_semaphores();

    pthread_t send_thread, recv_thread;

    // Initialize other variables if needed
    counter_messages_recv = 0;
    counter_messages_send = 0;
    counter_packages = 0;
    time_sum = 0.00;

    // Create threads for sending and receiving messages
    pthread_create(&send_thread, NULL, send_message, NULL);
    pthread_create(&recv_thread, NULL, receive_message, NULL);

    pthread_join(send_thread, NULL);
    pthread_join(recv_thread, NULL);

    printf("Process A finished\n");
    printf("\n");
    printf("\n");
    printf("------------------------------  STATS  -------------------------------\n");
    printf("SUM OF MESSAGES RECEIVED BY A: %d\n", counter_messages_recv);
    printf("SUM OF MESSAGES SENT BY A: %d\n", counter_messages_send);
    printf("SUM OF PACKAGES RECEIVED BY A: %d\n", counter_packages);

    float avg_package = (float)counter_packages / counter_messages_recv;
    printf("AVERAGE PACKAGES PER MESSAGE: %.2f\n", avg_package);

    double avg_time = time_sum / counter_messages_recv;
    printf("AVERAGE WAITING TIME FOR THE 1ST PACKAGE TO ARRIVE: %f sec\n", avg_time);
    printf("----------------------------------------------------------------------\n");

    printf("\n");
    printf("\n");
    char buffer[100];

    printf("Press ENTER for exit: ");
    fgets(buffer, sizeof(buffer), stdin);

    cleanup();
    return 0;
}
