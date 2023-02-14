#include <stdio.h>
#include <stdlib.h>
#include <string.h>



int main(int argc, char **argv)
{
    int i;
    char *username;
    char *array[argc];


    username = getenv("USER");
    if(username != NULL)
    {
        printf("This program is being executed by %s\n", username);
    }
    else
    {
        printf("ERROR: USER not defined\n");
        return EXIT_FAILURE;
    }

    for(i = 0 ; i < argc ; i++)
    {
      array[i] = argv[i];
    }

    for (int i = 1; i < argc; ++i) {
        printf("%s ", array[i]);
    }
   

    return EXIT_SUCCESS;
}   
