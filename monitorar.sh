#!/bin/bash
show_help() {
	echo '
Faz o monitoramento do banco de dados, mostrando as queries sendo executadas no momento e a quanto tempo está rodando
opções: 
	-c [0-9] Número de vezes o comando deve ser repetido. Padrão 99;
	-d [0-9] Delay para cada query em segundos. Pdrão 1.5
	--and clausula a ser adicionada na query. ex.: --and "xact_start NOTNULL"
	--show-null mostra resultados com Tempo Estimado nulo
	--until-null monitora até o resultado não retornar nada
'
}

delay_text () {
	if [ -t 1 ] ; then
		printf "%${#1}s\r" "|"
		for i in $(echo "$1" | grep -o .); do 
			sleep $(awk "BEGIN {print $2 / ${#1}}")
			printf $i;
		done
	else 
		echo $1
		sleep $2
	fi
}


. $PROPERTIES_FILE

COUNT=99
DB="hs_"
DELAY=1.5
FILTER="AND xact_start  NOTNULL "

while [ "$1" != "" ]; do
	case $1 in 
		-c) shift; COUNT=$1; shift;
		;;
		-d) shift; DELAY=$1; shift;
		;;
		--and) shift; AND=" AND $1"; shift;
		;;
		--help) show_help; exit 0 ;
		;;
		--show-null) FILTER=""; shift;
		;;
		--until-null) UNTIL_NULL="Y"; shift;
		;;
		* ) DB=$1; shift;
	esac
done
		
do_it() {
    delay_text "##################################################" ${DELAY}
    printf "\n\n"
    OUTPUT=`PGPASSWORD=${DB_PASSWORD} psql -h ${DB_SERVER} -p ${DB_PORT} -U ${DB_USER} -d template1 -t -A -c \
            "SELECT query , state , query_start , xact_start, query_start - xact_start FROM pg_catalog.pg_stat_activity WHERE datname ILIKE '%${DB}%' ${FILTER} ${AND}" \
            | awk -F "|" ' {print "query: " $1 "\n\nstate: " $2 "\nquery_start: " $3 "\nxact_start: " $4  "\nTempo de execução: " $5 "\n\n\n" }'`
    printf "${OUTPUT}\n\n\n"
}

printf "\n\n"
if [ "${UNTIL_NULL}" != "" ] ; then
	OUTPUT=text
	while [ "${OUTPUT}" != "" ] ; do
                do_it
	done
	exit 1;
else 
	for i in $(seq ${COUNT}) ; do 

		printf "Iteração Nº $i\n"
                do_it
	done
fi
