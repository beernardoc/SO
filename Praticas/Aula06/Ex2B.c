#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

/* SUGESTÂO: utilize as páginas do manual para conhecer mais sobre as funções usadas:
 man fopen
 man fgets
*/




int main(int argc, char *argv[])
{
    FILE *fp = NULL;
    int line;
    int numSize = 100;
    

    

    for(int i =  1; i < argc; i++){

    int *numbers;
    numbers = (int *) malloc(sizeof(int) * numSize);

 /* Open the file provided as argument */
    errno = 0;
        
    fp = fopen(argv[i], "r");

    if( fp == NULL )
    {
        perror ("Error opening file!");
        return EXIT_FAILURE;
    }

    while( fgets(line,numSize,fp) != NULL){
        numbers[i - 1] = line;
    }

    for(int j = 0;j < numbers;i++){
        printf("%d",numbers[i]);
            }

   

    fclose(fp);

    }

  
   

    

    return EXIT_SUCCESS;
}
