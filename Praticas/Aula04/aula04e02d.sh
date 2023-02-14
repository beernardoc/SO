#!/bin/bash

function teste_numero(){
    if [[ $1 = $2 ]]; then
        return 0
    elif [[ $1 -gt $2 ]]; then
        return 1
    else
        return 2
    fi
    
}

teste_numero $1 $2
echo "$?"