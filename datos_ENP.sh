#!/bin/bash

# Estudiante: Liliana Aguilar 
# Curso GNU-LINUX Línea de comandos
# Proyecto final

#Permisos:
# chmod 755 datos_ENP.sh
# ./datos_ENP.sh [NOMBRE ARCHIVO]
# Lo anterior generará un archivo CSV con la información solicitada de las 9 estaciones ENP para los meses que se tienen registro
# del año 2022, se procesaron para este objetivo 87 archivos CSV.
#

OUTPUT="resultados_ENP.csv"
echo "Estación,Longitud,Latitud,Tmax,Pmax,Date" > "$OUTPUT"

for ENP in {1..9}; do
    ESTACION="ENP${ENP}"
    
    COORD_OBTENIDAS=0
    
    for MES in {01..12}; do
        ARCHIVO="/LUSTRE/tmp/temp/estaciones-ENP/2022-${MES}-${ESTACION}-L1.CSV"
        
        [ -f "$ARCHIVO" ] || continue
        
        if [ $COORD_OBTENIDAS -eq 0 ]; then
            # Aquí hay que forzar longitud negativa para México (W)
            LAT=$(grep -oP 'Lat\s+\K[0-9]+\.[0-9]+' "$ARCHIVO" | head -1)
            LON=$(grep -oP 'Lon\s+\K\-?[0-9]+\.[0-9]+' "$ARCHIVO" | head -1)
            
            # Asegurarnos de que la longitud sea negativa
            if [[ -n "$LON" && ! "$LON" =~ ^- ]]; then
                LON="-${LON}"
            fi
            
            if [[ -n "$LAT" && -n "$LON" ]]; then
                COORD_OBTENIDAS=1
            else
                continue
            fi
        fi
        
        # Obtener Tmax (reemplazamos los valores vacíos con 0)
        Tmax=$(awk -F',' '
        NR > 8 && $1 != "" && $2 != "null" { 
            if ($2+0 == $2) {
                printf "%.1f\n", $2
            }
        }' "$ARCHIVO" | sort -nr | head -1)
        
        [ -z "$Tmax" ] && Tmax="0.0"
        
        # Obtener Pmax (reemplazamos lod valoeres vacíos con 0)
        Pmax=$(awk -F',' '
        NR > 8 && $1 != "" && $9 != "null" { 
            if ($9+0 == $9) {
                printf "%.1f\n", $9
            }
        }' "$ARCHIVO" | sort -nr | head -1)
        
        [ -z "$Pmax" ] && Pmax="0.0"
        
        echo "${ESTACION},${LON},${LAT},${Tmax},${Pmax},2022-${MES}" >> "$OUTPUT"
    done
done

# Notas adicionales:
# Se reemplazan los valores "null" como 0 sin dato para que no generara problema al momentos de realizar los máximos y que la gráfica pueda visualizarse al moemnto de llamar el script de python
## Corrección: Forzar longitud negativa para México (W), debido a que en este comentario, las longitudes
# en los archivos de las ENP vienen positivas y W, hay que pasarlos a negativos para que sean correctas 
#las coordenadas
# Se agregó formato con printf y awk para los datos numéricos y que mostrara solo un decimal después del #punto.
# Esta parte:  COORD_OBTENIDAS=0, sirve como una notificacion para saber si ya se procesaron los datos de
# longitud y latitud, llevar el control de lectura de coordenadas de cada etacion.
# Se agrga esta linea: [ -f "$ARCHIVO" ] || continue, para verificar si el archivo existe. Caso contrario,
# este continua con la siguiente iteracion.
# Se añade if [ $COORD_OBTENIDAS -eq 0 ]; then solo si aun no se han extraido las coordenadas en los metadatos
# de cada estacion
# Se hace uso de regex (expresiones regulares) perl:LAT=$(grep -oP 'Lat\s+\K[0-9]+\.[0-9]+' "$ARCHIVO" |
# head -1 ) este tipo de expresiones son mas detalladas con grep -oP, despues de extrae latitud, seguido de la
#captura de numeros decimales
# como se vio en clase: awk -F',': Procesa el CSV usando coma como separador.
# NR > 8: Omite las primeras 8 líneas (del encabezado o de los metadatos).
# $1 != "" && $2 != "null": Filtra filas no vacías y valores no nulos, como mencionamos arriba en la primera 
#descripcion.
# Para la parte de: $2+0 == $2, con esto verifcamos si el valor es un numero
# Los valores aparecen solo a un numero decimal agregando esta linea: printf "%.1f\n", $2, como ya tambien se 
#habia mencionado anteriromente
#Para ordenarlos de manera descendente y tomar el máximo se añade: sort -nr | head -1
