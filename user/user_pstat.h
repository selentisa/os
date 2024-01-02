#ifndef USER_PSTAT_H
#define USER_PSTAT_H

// #include "../kernel/proc.h"
#include "../kernel/types.h"
#include "../kernel/param.h"

struct user_pstat
{
    int pid[NPROC];
    char name[NPROC][16];
    uint sz[NPROC];
    // char types[NPROC];
};

extern struct user_pstat u_pstat[NPROC];
// struct user_pstat *user_pstat[NPROC];
#endif // USER_PSTAT_H
