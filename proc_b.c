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
        shared_memory->mess2_size = size;
        // printf("size: %d\n", size);
        //  shared_memory->f = 1;
        shared_memory->timestamp2 = time(NULL);
        sem_post(sem6);

        for (int i = 0; i <= (size); i += 15)
        {

            strncpy(shared_memory->mess2, temp + i, 15);

            // shared_memory->mess1[3] = '\0';
            //  printf("mess1: %s\n", shared_memory->mess2);
            sem_post(sem2);

            sem_wait(sem4);
            // printf("finally! B posted sem3\n");
        }
        // shared_memory->f = 0;
        counter_messages_send++;
        if (strcmp(temp, "#BYE#") == 0)
        {
            printf("Process B is going to terminate\n");
            shared_memory->f = 0;
            counter_messages_recv--;
            counter_packages--;
            // thread_cancel(*(pthread_t *)arg);
        }
    }
    return NULL;
}

void *receive_message(void *arg)
{

    while (shared_memory->f)
    {

        sem_wait(sem5);
        int size = shared_memory->mess1_size;
        char mess[256] = "";

        for (int i = 0; i <= size; i += 15)
        {

            sem_wait(sem1);
            if (i == 0)
            {
                shared_memory->timestamp3 = time(NULL);
                time_sum += difftime(shared_memory->timestamp3, shared_memory->timestamp1);
            }
            strcat(mess, shared_memory->mess1);
            counter_packages++;
            sem_post(sem3);
        }
        printf("\033[0;31mA: %s\n\033[0m\n", mess);
        // printf("message by proc A: %s\n", mess);
        counter_messages_recv++;
        if (strcmp(mess, "#BYE#") == 0)
        {
            printf("Press Enter to terminate\n");
            shared_memory->f = 0;
            counter_messages_send--;
            break;
        }
        // counter_messages_recv++;
        //  sem_post(sem3);
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

    // Wait for threads to complete
    pthread_join(send_thread, NULL);
    pthread_join(recv_thread, NULL);

    printf("Process B finished\n");
    printf("\n");
    printf("\n");
    printf("------------------------------  STATS  -------------------------------\n");
    printf("SUM OF MESSAGES RECEIVED BY B: %d\n", counter_messages_recv);
    printf("SUM OF MESSAGES SENT BY B: %d\n", counter_messages_send);
    printf("SUM OF PACKAGES RECEIVED BY B: %d\n", counter_packages);

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