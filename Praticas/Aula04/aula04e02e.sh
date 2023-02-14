#!/bin/bash

function teste_numero(){
    
    echo "Digite dois numeros: "
    read var1 var2

    if [[ $var1 = $var2 ]]; then
        return 0
    elif [[ $var1 -gt $var2 ]]; then
        return 1
    else
        return 2
    fi


    
}

teste_numero
echo "$?"