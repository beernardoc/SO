#!/bin/bash
function imprime_msg()
{
    echo "A minha primeira funcao"
    return 0
}


function data(){
    
    echo "A data de hoje é: $(date)" 
    echo "Utilizador: $(who)"
    echo "PC: $(whoami)"
    return 0
}
imprime_msg
data