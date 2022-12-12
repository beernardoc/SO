#!/bin/bash


# c - expressao regular
# u - seleção por nome
# p - numero de processos a serem exibidos
# s - data minima 
# e - data max
# m M - pids
# r - reverse
# w - sort pelos write values

c_flag=0
u_flag=0
p_flag=0
s_flag=0
e_flag=0
m_flag=0
M_flag=0
r_flag=0
w_flag=0

error_message(){
    echo "
TODAS AS OPÇÕES VÁLIDAS:
    ./rwstat.sh <FILTROSTEMPO>, em que os TEMPO é o número de segundos que serão usados para calcular as taxas de I/O,
    logo o último argumento passado é obrigatoriamente em segundos.

    FILTROS são por sua vez filtros de procura:
        FILTROS DE PROCURA:
            -c <OPTION> : filtra processos baseados no nome do comando atraves de uma expressão regular (regex); 
            -u <OPTION> : filtra processos pelo nome do utilizador;
            -p <OPTION> : o número de processos que vão aparecer na tabela;
            -m <OPTION> : filtro em que OPTION é o número minimo de PID;
            -M <OPTION> : filtro em que OPTION é o número máximo de PID;
        FILTROS DE DATAS:
            -s <DATE> : filtro em que DATE é a data mínima do início do processo;
            -e <DATE> : filtro em que DATE é a data máxima do início do processo;
        FILTROS DE ORDEM:
            -r : inverte as posições em que os items aparecem na tabela (reverse);
            -w : ordena os items da tabela através dos valores 'escritos' por cada um (write values);
    "
}


declare -a PIDs # declara array que guarda todos os PIDs na diretoria /proc/
declare -a read_bytes # array que guarda o rchar de cada PID
declare -a writen_bytes # array que guarda o wchar de cada PID
declare -a info; #declarar array que vai guardar todas as informações de cada PID
declare -a user_input;
cont=0

for i in $@ 
do
    
    user_input[cont]=$i   # declaração de array para salvar e deixar acessivel os valores de @
    cont=$((cont+1))

done

if [[ ${#user_input[@]} -eq 1 ]];then
    tempo=${user_input[0]}  ### rwstat.sh 10
elif [[ ${#user_input[@]} -gt 1 ]];then
    tempo=${user_input[-1]}
fi

# echo "tempo: ""$tempo"


if [[ ! $tempo =~ ^[0-9]+$ ]];then  #verifico se o ultimo parametro é um numero 
 echo "O ultimo argumento deve ser um numero (tempo em segundos)"
 error_message
 exit 1
elif [[ ${#user_input[@]} -gt 1 ]] && [[ ${user_input[-2]} = "-c" || ${user_input[-2]} = "-u" || ${user_input[-2]} = "-p" || 
${user_input[-2]} = "-s" || ${user_input[-2]} = "-e" || ${user_input[-2]} = "-m" || ${user_input[-2]} = "-M" ]];then  # ultimo ja é um numero
 echo "O argumento ""${user_input[-2]}"" necessita de um parametro" 
 error_message
 exit 1
fi

todos_argumentos=$@

if [[ ${#user_input[@]} -gt 1 ]];then
argumentos_validos=${todos_argumentos:0:-$((${#tempo}))} # selecionando as opções passadas sem o ultimo parametro (tempo).
                                                         # todos_argumentos = -c 10 -p 10 -> argumentos_validos = -c 10 -p
else
argumentos_validos=$todos_argumentos   # swstat.sh 10 
fi

# echo "Todos argumentos: ""$todos_argumentos"
# echo "Argumentos validos: ""$argumentos_validos"

for j in $argumentos_validos
do
 if [[ $j = "-c" || $j = "-u" || $j = "-p" || $j = "-s" || $j = "-e" || $j = "-m" || $j = "-M" ]];then
    options="$options""${j:1}"":"   ### concatenar string de opções que necessitam de argumentos (:)
 elif [[ $j = "-r" || $j = "-w" ]];then
    options="$options""${j:1}" ### concatenar string de opções que nao necessitam de argumentos
 fi
done

# echo "$options"
while getopts "$options" opt; do  #argumentos seguidos de : tem como obrigatoriedade a passagem de arguemtnos (nao é necessario if dentro da opt)

    case "${opt}" in
        c ) 
            name_comm=${OPTARG}
            c_flag=$((c_flag+1))         # flag será usado para saber se a opção foi escolhida (flag = 1) e se foi chamada mais de uma vez (flag > 1 -> ERRO)
            #echo "$name_comm"
        ;;

        u )
            name_user=${OPTARG}
            u_flag=$((u_flag+1))
            #echo "$name_user"
        ;;

        p ) 
            num_proc=${OPTARG}
            p_flag=$((p_flag+1))
            #echo "$num_proc"
        ;;

        s ) 
            data_min=${OPTARG}
            datamin=`date +"%Y/%m/%d" -d "${data_min}"`
            horamin=$(date -u -d `echo "${data_min:6}"` +"%s")
            s_flag=$((s_flag+1))
            #echo "$data_min"
        ;;

        e )
            data_max=${OPTARG}
            datamax=`date +"%Y/%m/%d" -d "${data_max}"`
            horamax=$(date -u -d `echo "${data_max:6}"` +"%s")
            e_flag=$((e_flag+1))
            #echo "$data_max"
        ;;

        m ) 
            pids1=$OPTARG
            m_flag=$((m_flag+1))
                                            #DESCOBRIR SE O m e M podem ter a mesma variavel como referencia pids
            #echo "$pids1"
        ;;

        M ) 
            pids2=$OPTARG
            M_flag=$((M_flag+1))
            #echo "$pids2"
        ;;

        ############### ORDENAÇÃO (NAO NECESSITAM DE ARGUMENTOS)

        r ) 
            r_flag=$((r_flag+1))
            #echo "r"
        ;;

        w ) 
            w_flag=$((w_flag+1))
            #echo "w"
        ;;

    esac

done


#### caso flag > 1 significa que aquela opção foi repetida -> ERRO ####

if [[ c_flag -gt 1 ]] || [[ u_flag -gt 1 ]] || [[ p_flag -gt 1 ]] || [[ s_flag -gt 1 ]] || [[ e_flag -gt 1 ]] || [[ m_flag -gt 1 ]] || 
[[ M_flag -gt 1 ]] || [[ c_flag -gt 1 ]] || [[ r_flag -gt 1 ]] || [[ w_flag -gt 1 ]]; then
        echo "Foram escolhidas opções repetidas"
        error_message
        exit 1
        
fi

cd /proc # acede à diretoria
for pid in *[0-9] ; do # for loop para todos os items com numeros (neste caso só os PIDs)
    if [[ -f "$pid/io" ]] && [[ -r "$pid/io" ]] && [[ -f "$pid/comm" ]] && [[ -f "$pid/status" ]]; then # ve se /proc/PID/io file existe e é readable
    # (-f --> vê se exite do tipo FILE) (-r -> vê se é readable); vê se comm e status de cada pid tambem sao readable
        PIDs+=($pid) # adiciona cada PID ao araay
        READB=$(cat $pid/io | grep -i 'rchar' | grep -o -E '[0-9]+')
        read_bytes+=($READB) # adiciona o rchar de cada PID ao array
        WRITEB=$(cat $pid/io | grep -i 'wchar' | grep -o -E '[0-9]+')
        writen_bytes+=($WRITEB) # adiciona o wchar de cada PID ao array
        #read_bytes e writen_bytes vão ser usados para calcular o resto (raters) depois do sleep
    fi
done

 sleep $tempo # input dos tempo


# ${#array[@]} ----> tamanho de um array
# echo "${PIDs[*]}" #printa o array


for (( i = 0; i < ${#PIDs[@]}; i++ )); do
    pid="${PIDs[$i]}" #vai buscar o pid na posição i
    if [[ -f "$pid/io" ]] && [[ -r "$pid/io" ]] && [[ -f "$pid/comm" ]] && [[ -f "$pid/status" ]]; then # as mesmas verificações de cima
        COMM=$(cat $pid/comm | tr " " "_") # este tr é usado para substituir os espaços por um "" para não dar erro futuramente
        USER=$(ps -o uname= -p "$pid")
        DATE=$(ls -ld "$pid" | awk '{printf("%s %s %s\n", toupper( substr( $6, 1, 1 ) ) substr( $6, 2 ), $7, $8)}') #toupper e substr --> o primeiro char do mês maiusculo
        READB2=$(cat $pid/io | grep -i 'rchar' | grep -o -E '[0-9]+')
        WRITEB2=$(cat $pid/io | grep -i 'wchar' | grep -o -E '[0-9]+')
        RATER=$(echo "scale=2; ($READB2-${read_bytes[$i]})/$tempo" | bc -l ) # scale=2 para ter 2 casas decimais e bc -l para usar a math library
        RATEW=$(echo "scale=2; ($WRITEB2-${writen_bytes[$i]})/$tempo" | bc -l )

        READB=$(expr $READB2 - ${read_bytes[$i]})
        WRITEB=$(expr $WRITEB2 - ${writen_bytes[$i]})

        info+=($COMM $USER $pid $READB $WRITEB $RATER $RATEW $DATE) # guarda toda a informação de cada PID 
    fi
done

#echo "${info[@]}"

##################### COMM (c) #############33

declare -a temp

if [[ $c_flag -eq 1 ]];then #-c
    for (( i = 0; i < ${#info[@]}; i=$((i+10)) ));do
     if [[ "${info[i]}" =~ $name_comm ]];then
        temp+=(${info[i]} ${info[i+1]} ${info[i+2]} ${info[i+3]} ${info[i+4]} ${info[i+5]} ${info[i+6]} ${info[i+7]} ${info[i+8]} ${info[i+9]})
     fi
    done
    
    info=("${temp[@]}")
    temp=()                              
fi

################## USER (u) ##################3


if [[ $u_flag -eq 1 ]];then #-u
     for (( i = 1; i < ${#info[@]}; i=$((i+10)) ));do
      if [[ "${info[i]}" == $name_user ]];then
         temp+=(${info[i-1]} ${info[i]} ${info[i+1]} ${info[i+2]} ${info[i+3]} ${info[i+4]} ${info[i+5]} ${info[i+6]} ${info[i+7]} ${info[i+8]})
      fi
     done
    
    info=("${temp[@]}")
        temp=()                   
fi

############# PIDS (m M) ###############3

if [[ $m_flag -eq 1 ]];then #-m
    for (( i = 2; i < ${#info[@]}; i=$((i+10)) ));do
        if [[ $M_flag -eq 0 && ${info[i]} -ge $pids1 ]] ;then #-m 
         temp+=(${info[i-2]} ${info[i-1]} ${info[i]} ${info[i+1]} ${info[i+2]} ${info[i+3]} ${info[i+4]} ${info[i+5]} ${info[i+6]} ${info[i+7]})
        elif [[ ${info[i]} -ge $pids1 && ${info[i]} -le $pids2 ]];then #-m e -M
         temp+=(${info[i-2]} ${info[i-1]} ${info[i]} ${info[i+1]} ${info[i+2]} ${info[i+3]} ${info[i+4]} ${info[i+5]} ${info[i+6]} ${info[i+7]})
        fi
    done 

 info=("${temp[@]}")
 temp=() 


elif [[ $M_flag -eq 1 ]];then #-M
    for (( i = 2; i < ${#info[@]}; i=$((i+10)) ));do
        if [[ ${info[i]} -le $pids2 ]];then
         temp+=(${info[i-2]} ${info[i-1]} ${info[i]} ${info[i+1]} ${info[i+2]} ${info[i+3]} ${info[i+4]} ${info[i+5]} ${info[i+6]} ${info[i+7]})
        fi
    done 

 info=("${temp[@]}")
 temp=()
fi

################### DATA (S E) ###################3

if [[ $s_flag -eq 1 ]];then #-s

    for (( i = 7; i < ${#info[@]}; i=$((i+10)) ));do
        dataatual="${info[i]}"" ""${info[i+1]}"
        horaatual=$(date -u -d `echo "${info[i+2]}"`  +"%s")
        if [[ $e_flag -eq 0 ]];then #-s
            if [[ `date +"%Y/%m/%d" -d "${dataatual}"` > $datamin ]];then 
                temp+=(${info[i-7]} ${info[i-6]} ${info[i-5]} ${info[i-4]} ${info[i-3]} ${info[i-2]} ${info[i-1]} ${info[i]} ${info[i+1]} ${info[i+2]})
            elif [[ `date +"%Y/%m/%d" -d "${dataatual}"` == "$datamin" ]] && [[ $horaatual -ge $horamin ]];then
                temp+=(${info[i-7]} ${info[i-6]} ${info[i-5]} ${info[i-4]} ${info[i-3]} ${info[i-2]} ${info[i-1]} ${info[i]} ${info[i+1]} ${info[i+2]})
            fi
        else #-s -e
            if [[ `date +"%Y/%m/%d" -d "${dataatual}"` > $datamin ]] && [[ `date +"%Y/%m/%d" -d "${dataatual}"` < $datamax ]] ;then
                temp+=(${info[i-7]} ${info[i-6]} ${info[i-5]} ${info[i-4]} ${info[i-3]} ${info[i-2]} ${info[i-1]} ${info[i]} ${info[i+1]} ${info[i+2]})
            elif [[ `date +"%Y/%m/%d" -d "${dataatual}"` == $datamin ]] && [[ $horaatual -ge $horamin ]];then
                if [[ `date +"%Y/%m/%d" -d "${dataatual}"` < $datamax ]];then
                    temp+=(${info[i-7]} ${info[i-6]} ${info[i-5]} ${info[i-4]} ${info[i-3]} ${info[i-2]} ${info[i-1]} ${info[i]} ${info[i+1]} ${info[i+2]})
                elif [[ `date +"%Y/%m/%d" -d "${dataatual}"` == $datamax ]] && [[ $horaatual -le $horamax ]];then
                    temp+=(${info[i-7]} ${info[i-6]} ${info[i-5]} ${info[i-4]} ${info[i-3]} ${info[i-2]} ${info[i-1]} ${info[i]} ${info[i+1]} ${info[i+2]})
                fi
            elif [[ `date +"%Y/%m/%d" -d "${dataatual}"` == $datamax ]] && [[ $horaatual -le $horamax ]];then
                if [[ `date +"%Y/%m/%d" -d "${dataatual}"` > $datamin ]];then
                    temp+=(${info[i-7]} ${info[i-6]} ${info[i-5]} ${info[i-4]} ${info[i-3]} ${info[i-2]} ${info[i-1]} ${info[i]} ${info[i+1]} ${info[i+2]})
                elif [[ `date +"%Y/%m/%d" -d "${dataatual}"` == "$datamin" ]] && [[ $horaatual -ge $horamin ]];then
                    temp+=(${info[i-7]} ${info[i-6]} ${info[i-5]} ${info[i-4]} ${info[i-3]} ${info[i-2]} ${info[i-1]} ${info[i]} ${info[i+1]} ${info[i+2]})
                fi
            fi
        fi
    done 
     
 info=("${temp[@]}")
 temp=() 

elif [[ $e_flag -eq 1 ]];then #-e

    for (( i = 7; i < ${#info[@]}; i=$((i+10)) ));do   
        dataatual="${info[i]}"" ""${info[i+1]}"
        horaatual=$(date -u -d `echo "${info[i+2]}"` +"%s")
        if [[ `date +"%Y/%m/%d" -d "${dataatual}"` < $datamax ]] ;then 
            temp+=(${info[i-7]} ${info[i-6]} ${info[i-5]} ${info[i-4]} ${info[i-3]} ${info[i-2]} ${info[i-1]} ${info[i]} ${info[i+1]} ${info[i+2]})
        elif [[ `date +"%Y/%m/%d" -d "${dataatual}"` == $datamax ]] && [[ $horaatual -le $horamax  ]];then
            temp+=(${info[i-7]} ${info[i-6]} ${info[i-5]} ${info[i-4]} ${info[i-3]} ${info[i-2]} ${info[i-1]} ${info[i]} ${info[i+1]} ${info[i+2]})
        fi
    done 

 info=("${temp[@]}")
 temp=() 
fi

if [[ $w_flag -eq 1 ]];then #-w

    declare -a write_order
    temp=("${info[@]}") # para fazer alterações sem mudar o user_input principal
    while [ ${#temp[@]} != 0 ];do
        max=${temp[4]} # primeiro
        comp=0
        
        for (( i=4; i <= ((${#temp[@]}-5)); i=$((i+10)) ));do
            if [[ $max -lt ${temp[$i]} ]];then
                max=${temp[$i]}
                comp=$((i-4)) # vai dar o valor onde esta o menor para depois ajudar na remoção
            fi
        done
        # write_order+=("${temp[@]:$comp:$((comp+10))}")
        write_order+=(${temp[comp]} ${temp[comp+1]} ${temp[comp+2]} ${temp[comp+3]} ${temp[comp+4]} ${temp[comp+5]} ${temp[comp+6]} ${temp[comp+7]} ${temp[comp+8]} ${info[comp+9]})
        temp=("${temp[@]:0:$comp}" "${temp[@]:$((comp+10))}")

    done
    temp=()
    info=("${write_order[@]}")
fi

################ REV (r) #############

if [[ $r_flag -eq 1 ]];then #-r
    for (( i=((${#info[@]}-1)) ; i >= 0; i=$((i-10)) ));do
     temp+=(${info[i-9]} ${info[i-8]} ${info[i-7]} ${info[i-6]} ${info[i-5]} ${info[i-4]} ${info[i-3]} ${info[i-2]} ${info[i-1]} ${info[i]})
    done

    info=("${temp[@]}")
    temp=() 
fi

################## NUMERO PROC (p) ##############
if [[ $p_flag -eq 1 ]];then #-p
     for (( i = 0 ; i < 10*($num_proc); i++ ));do
         temp+=(${info[i]})
     done

      info=("${temp[@]}")
      temp=()       
fi

#echo "${temp[*]}"
if [[ ${#info[@]} -eq 0 ]];then
    echo 'Não exitem processos ativos que cumpram esses filtros no espaço de tempo dado'
    error_message
else
    # vai dar print á tabela
    printf "%-30s %-12s %12s %16s %16s %12s %12s %15s \n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"

    for (( i = 0; i <  ${#info[@]}; i=$((i+10)) ));do
        # echo "${info[i]} ${info[i+1]} ${info[i+2]} ${info[i+3]} ${info[i+4]} ${info[i+5]} ${info[i+6]} ${info[i+7]} ${info[i+8]} ${info[i+9]}"
        printf "%-30s %-12s %12s %16s %16s %12s %12s %15s \n" "${info[i]}" "${info[i+1]}" "${info[i+2]}" "${info[i+3]}" "${info[i+4]}" "${info[i+5]}" "${info[i+6]}" "${info[i+7]} ${info[i+8]} ${info[i+9]}"
    done
fi
