#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

typedef struct
{
    int age;
    double height;
    char name[64];
} Person;

void printPersonInfo(Person *p)
{
    printf("Person: %s, %d, %f\n", p->name, p->age, p->height);
}

int main (int argc, char *argv[])
{
    FILE *fp = NULL;
    int i,Quant;

   

    Person p;

    

    /* Validate number of arguments */
    if(argc != 2)
    {
        printf("USAGE: %s fileName\n", argv[0]);
        return EXIT_FAILURE;
    }

    printf("Number of people: ");
    scanf("%d", &Quant);
    //printf("%d",Quant);


    /* Open the file provided as argument */
    errno = 0;
    fp = fopen(argv[1], "wb");
    if(fp == NULL)
    {
        perror ("Error opening file!");
        return EXIT_FAILURE;
    }

    /* Write 10 itens on a file */
    for(i = 0 ; i < Quant ; i++)
    {    
        
        
        printf("Name of people %d: ",i);
        scanf("%s", p.name);
        printf("Height of people %d: ",i);
        scanf("%lf", &p.height);
        printf("Age of people %d: ",i);
        scanf("%d", &p.age);


        

        fwrite(&p, sizeof(Person),1,fp);
        
    }

    fclose(fp);

    return EXIT_SUCCESS;
}
