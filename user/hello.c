#include "../kernel/types.h"
#include "../kernel/stat.h"
#include "user.h"
#include "../kernel/syscall.h"
#include "user_pstat.h"

// truct user_pstat u_pstat[];
struct user_pstat u_pstat[NPROC];
int main()
{
    // printf("lala\n");
    // uint64 active = processinf();

    int a = processinf();

    for (int i = 0; i < a; i++)
    {
        // printf("%d\n", u_pstat->pid[i]);
        a += 1;
    }

    exit(0);
}