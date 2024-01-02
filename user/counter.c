#include "../kernel/types.h"
#include "../kernel/stat.h"
#include "user.h"

int main(int argc, char *argv[])
{
    if (argc != 2)
    {
        printf("Usage: counter <number>\n");
        exit(1);
    }

    int n = atoi(argv[1]);

    if (n <= 0)
    {
        printf("Please provide a positive integer greater than zero.\n");
        exit(1);
    }

    for (int i = 1; i <= n; ++i)
    {
        printf("%d\n", i);
    }
    exit(0);
}
