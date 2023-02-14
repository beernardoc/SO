#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* SUGESTÂO: utilize as páginas do manual para conhecer mais sobre as funções usadas:
 man system
 man date
*/

int main(int argc, char *argv[])
{
    char text[1024];
    FILE *fp;
    struct tm *data_hora_atual;     

    fp = fopen("command.log", "a") ;



    
    do
    {
        printf("Command: ");
        scanf("%1023[^\n]%*c", text);
        time_t segundos;
        time(&segundos);   
        data_hora_atual = localtime(&segundos);  
        


        fprintf(fp,"%s %d:%d:%d\n",text,data_hora_atual->tm_hour,data_hora_atual->tm_min,data_hora_atual->tm_sec);

        /* system(const char *command) executes a command specified in command
            by calling /bin/sh -c command, and returns after the command has been
            completed.
        */
        if(strcmp(text, "end")) {
           printf("\n * Command to be executed: %s\n", text);
           printf("---------------------------------\n");
           system(text);
           printf("---------------------------------\n");
        }
    } while(strcmp(text, "end"));

    printf("-----------The End---------------\n");

    return EXIT_SUCCESS;
}