
#!/bin/bash
# Conditional block if
if [[ $1 -gt 5 && $1 -lt 10 ]]   ; then
echo "Numero dentro do intervalo [5,10]"
else
echo "NUmero fora do intervalo [5,10]"
fi