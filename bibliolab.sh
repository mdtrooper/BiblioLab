#!/bin/bash

# Usamos trap para no permitir cerrar con control+C
trap '' 1 2 3 15 20

# Desactivamos la tecla ESC
echo -e "keymaps 0-127\nkeycode 1 =" > /tmp/key.map
loadkeys /tmp/key.map

# archivo con el listado de libros
db="libros.csv"

dialog --no-shadow --colors --no-lines --no-kill --infobox "    \ZbBienvenid@ amig@\ZB \n  --------------------\n  2017 IngoberLAB #301\n  --------------------\n  BiblioLAB 0.1 - fiwi\n  --------------------\n  _.-._.-._.-._.-._.-_" 10 30
sleep 5

paso1=0

hacer_backup()
{
	timestamp=$(date +%s)
	cp $db "$db.$timestamp"
}

anyadir_libro()
{
	while read -r libro || [[ -n $libro ]]
	do
		id=$(echo $libro | cut -d ";" -f 1)
	done < "$db"
	
	nuevo_id=$(( id + 1 ))
	nuevo_libro=$(dialog --no-shadow --colors --no-lines --no-kill --inputbox "Título del nuevo libro:" 0 0 --output-fd 1)
	nuevo_libro=$(echo -n $nuevo_libro | sed "s/;/ /g")
	if [ $? -ne 1 ]
	then
		if [ ! -z "$nuevo_libro" ]
		then
			hacer_backup
			
			echo -e "$nuevo_id;$nuevo_libro;0;disponible" >> $db
		else
			dialog --no-shadow --colors --no-lines --no-kill --msgbox "No seas Troll mete un título para el libro." 0 0
		fi
	fi
}

borrar_libro()
{
	while read -r libro || [[ -n $libro ]]
	do
		id=$(echo $libro | cut -d ";" -f 1)
		titulo=$(echo $libro | cut -d ";" -f 2)
		estado=$(echo $libro | cut -d ";" -f 3)
		correo=$(echo $libro | cut -d ";" -f 4)
		if [ $estado -eq 0 ]
		then
			libros+=("$id" "$titulo")
		else
			libros+=("$id" "\Zb$titulo ($correo)\ZB")
		fi
	done < "$db"
	unset libro
	
	opcion=$(dialog --no-shadow --colors --no-lines --no-kill --menu "\Zb¿QUÉ LIBRO QUIERES BORRAR?\ZB" 0 0 0 "${libros[@]}" --output-fd 1)
	unset libros
	
	if [ $? -ne 1 ]
	then
		if [ ! -z "$opcion" ]
		then
			hacer_backup
			
			listado_libro_borrado=$(grep libros.csv -v -e "^$opcion;" | cut -d ";" -f 2-4)
			
			echo -n "" > $db
			
			IFS=$'\n'
			i=1
			for libro in $listado_libro_borrado
			do
				if [ -n "$libro" ]
				then
					echo "$i;$libro" >> $db
					i=$(( $i + 1 ))
				fi
			done
		else
			unset opcion
		fi
	fi
}

editar_libro()
{
	while read -r libro || [[ -n $libro ]]
	do
		id=$(echo $libro | cut -d ";" -f 1)
		titulo=$(echo $libro | cut -d ";" -f 2)
		estado=$(echo $libro | cut -d ";" -f 3)
		correo=$(echo $libro | cut -d ";" -f 4)
		if [ $estado -eq 0 ]
		then
			libros+=("$id" "$titulo")
		else
			libros+=("$id" "\Zb$titulo ($correo)\ZB")
		fi
	done < "$db"
	unset libro
	
	opcion=$(dialog --no-shadow --colors --no-lines --no-kill --menu "\Zb¿QUÉ LIBRO QUIERES EDITAR?\ZB" 0 0 0 "${libros[@]}" --output-fd 1)
	unset libros
	
	if [ $? -ne 1 ]
	then
		if [ ! -z "$opcion" ]
		then
			titulo_antiguo=$(grep libros.csv -e "^$opcion;" | cut -d ";" -f 2)
			
			nuevo_titulo=$(dialog --no-shadow --colors --no-lines --no-kill --inputbox "Editar libro:" 0 0 "$titulo_antiguo" --output-fd 1)
			nuevo_titulo=$(echo -n $nuevo_titulo | sed "s/;/ /g")
			
			hacer_backup
			
			echo -n "" > "temp"
			
			head -n$(( $opcion - 1)) $db >> "temp"
			echo -n "$opcion;$nuevo_titulo;$(grep $db -e "^$opcion;" | cut -d";" -f3-4)" >> "temp"
			tail -n+$(($opcion + 1)) $db >> "temp"
			mv "temp" $db
		else
			unset opcion
		fi
	fi
}

editar_biblioteca()
{
	unset opciones
	opciones=(0 "Añadir libro")
	opciones+=(1 "Borrar libro")
	opciones+=(2 "Editar libro")
	opcion=$(dialog --no-shadow --colors --no-lines --no-kill --menu "\ZbEditar Biblioteca\ZB" 0 0 0 "${opciones[@]}" --output-fd 1)
	
	case $opcion in
		0)
			anyadir_libro
			;;
		1)
			borrar_libro
			;;
		2)
			editar_libro
			;;
	esac
}

while true
do
	if [ $paso1 -eq 0 ]
	then
		libros=(0 "Editar Biblioteca")
		while read -r libro || [[ -n $libro ]]
		do
			id=$(echo $libro | cut -d ";" -f 1)
			titulo=$(echo $libro | cut -d ";" -f 2)
			estado=$(echo $libro | cut -d ";" -f 3)
			correo=$(echo $libro | cut -d ";" -f 4)
			if [ $estado -eq 0 ]
			then
				libros+=("$id" "$titulo")
			else
				libros+=("$id" "\Zb$titulo ($correo)\ZB")
			fi
		done < "$db"
		
		opcion=$(dialog --no-shadow --colors --no-lines --no-kill --no-cancel --menu "\ZbLIBROS DE BIBLIOLAB DISPONIBLES AHORA MISMO\ZB" 0 0 0 "${libros[@]}" --output-fd 1)
		unset libro
		
		if [ ! -z "$opcion" ]
		then
			paso1=1
			unset libros
		else
			unset opcion
		fi
	fi
	
	if [ $opcion -eq 0 ]
	then
		editar_biblioteca
		paso1=0
	else
		seleccionado=$(cat "$db" | head -n $opcion | tail -n 1)
		sid=$(echo $seleccionado | cut -d ";" -f 1)
		slibro=$(echo $seleccionado | cut -d ";" -f 2)
		status=$(echo $seleccionado | cut -d ";" -f 3)
		email=$(echo $seleccionado | cut -d ";" -f 4)
		
		if [ $status -eq 0 ]
		then
			op=$(dialog --no-lines --no-shadow --colors --no-lines --menu "$slibro" 10 0 2 "1" "Coger" --output-fd 1)
		else
			op=$(dialog --no-lines --no-shadow --colors --no-lines --menu "\Zb$slibro\ZB lo tiene $email" 10 0 2 "2" "Devolver" --output-fd 1)
		fi
		
		if [ $op ]
		then
			paso1=0
			if [ $op -eq 2 ]
			then
				sustitucion="$sid;$slibro;0;disponible"
				sed "s/$seleccionado/$sustitucion/g" "$db" > /tmp/tmp.csv
				cp /tmp/tmp.csv "$db"
			fi
			
			if [ $op -eq 1 ]
			then
				umail=$(dialog --no-shadow --colors --no-cancel --inputbox "Ha de escribir su \ZbEmail\ZB\nNo sea Troll. BiblioLAB se basa en la autogestión y la confianza: " 10 0 --output-fd 1)
				sustitucion="$sid;$slibro;1;$umail"
				sed "s/$seleccionado/$sustitucion/g" "$db" > /tmp/tmp.csv
				cp /tmp/tmp.csv "$db"
			fi
		else
			paso1=0
		fi
	fi
done
