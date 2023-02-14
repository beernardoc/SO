#!/bin/bash



DIRETORIO='/etc'
cd "$DIRETORIO"
echo "Todos os arquivos: " 
ls
echo 
echo "Todos cujo nome começa por a" 
ls -d a*
echo 
echo "Todos cujo nome começa por a e têm mais que 3 caractere"  
ls -d a???*
echo 
echo "Todos os que têm conf no nome."
ls -d *conf*



