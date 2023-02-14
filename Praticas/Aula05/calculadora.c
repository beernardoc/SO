#include <stdio.h>
#include <math.h>
#include <stdlib.h>


int main(int argc, char *argv[])
{   
    char *end;
    double number1;
    double number2;
    char op = *(argv[2]);
    double pot;


    if (argc != 4){
        printf("ERRO\n");
        return EXIT_FAILURE;  // ERRO PARA MAIS DE 3 ENTRADAS

        
    }
    else{

        number1 = strtod(argv[1],&end);

        if (end == argv[1] || *end != '\0'){ // SE O ULTIMO CHAR == ARGUMENTO (2a -> end = a, argv[1] = 2a -> Exitfailure) || se ultimo char != \0
            printf("ERRO\n");
            return EXIT_FAILURE;
        }

        number2 = strtod(argv[3],&end);
        if(end == argv[3] || *end != '\0'){
            printf("ERRO");
            return EXIT_FAILURE;
        }



        switch (op)
        {
            case '+':
                 printf("%.2f + %.2f = %.2f", number1,number2,number1 + number2);
                 break;
            case '-':
                printf("%.2f - %.2f = %.2f", number1,number2,number1 - number2);
                break;
            case '/':
                printf("%.2f/%.2f = %.2f", number1,number2,number1/number2);
                break;
            case 'x':
                printf("%.2f x %.2f = %.2f", number1,number2,number1 * number2);
                break;
            case 'p':
            pot = pow(number1,number2);
            printf("%.2f^%.2f = %.2f", number1,number2,pot);
            break;


        default:
            printf("ERRO");
            break;
        }

        return EXIT_SUCCESS;


    }
    
    
}