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

while true
do
	if [ $paso1 -eq 0 ]
	then
		while read -r libro
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
		done < $db
		
		opcion=$(dialog --no-shadow --colors --no-lines --no-kill --no-cancel --menu "\ZbLIBROS DE BIBLIOLAB DISPONIBLES AHORA MISMO\ZB" 0 0 0 "${libros[@]}" --output-fd 1)
		if [ ! -z "$opcion" ]
		then
			echo "la opcion es $opcion"
			paso1=1
			unset libros libro
		else
			unset opcion
		fi
	fi
	
	seleccionado=$(cat $db | head -n $opcion | tail -n 1)
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
			sed "s/$seleccionado/$sustitucion/g" $db > /tmp/tmp.csv
			cp /tmp/tmp.csv $db
		fi
		
		if [ $op -eq 1 ]
		then
			umail=$(dialog --no-shadow --colors --no-cancel --inputbox "Ha de escribir su \ZbEmail\ZB\nNo sea Troll. BiblioLAB se basa en la autogestión y la confianza: " 10 0 --output-fd 1)
			sustitucion="$sid;$slibro;1;$umail"
			sed "s/$seleccionado/$sustitucion/g" $db > /tmp/tmp.csv
			cp /tmp/tmp.csv $db
		fi
	else
		paso1=0
	fi
done