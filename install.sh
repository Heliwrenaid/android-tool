#!/bin/bash

BIN_DIR="/system/bin"
SAT_DIR=`dirname "$(readlink -f "$0")"`
OS_TYPE=`uname -o`
CONFIG_FILE="$SAT_DIR/default.conf"

#set environment
set_env () {
	FILE="$1"
	OS_TYPE="$2"
	ENV=`head -1 "$FILE"`
	if [[ "$ENV" != "#!/bin/bash" && "$OS_TYPE" == "Linux" ]]
	then
		awk  -v awkvar="$ENV" '{sub(awkvar,"#!/bin/bash")}1' "$FILE" > temp.txt && mv temp.txt "$FILE"
	fi
	
	if [[ "$ENV" != "#!/system/bin/bash" && "$OS_TYPE" == "Android" ]]
	then
		awk  -v awkvar="$ENV" '{sub(awkvar,"#!/system/bin/bash")}1' "$FILE" > temp.txt && mv temp.txt "$FILE" 
	fi
}

#no needed
add_to_path_unused () {
	CONTENT="$1"
	FILE="$2"
	echo 'export PATH="$PATH:' >> $FILE
	sed '$s/$/y4qsjhr3163ga335at35323far2os/' $FILE > _list.txt_ && mv _list.txt_ $FILE
	awk  -v awkvar="$CONTENT" '{sub("y4qsjhr3163ga335at35323far2os",awkvar)}1' $FILE > temp.txt && mv temp.txt $FILE
	sed '$s/$/"/' $FILE > _list.txt_ && mv -- _list.txt_ $FILE
	source $FILE
}

add_to_path () {
	PATH_TO_SAT='export PATH="$PATH:'"$1"'"'
	if [ -z "$(cat "$2" | grep "$PATH_TO_SAT")" ]
	then
		echo "$PATH_TO_SAT" >> "$2"
		source "$2"
	fi
}

install_on_android () {
	mkdir -p $BIN_DIR
	cp -f $SAT_DIR/bin/$ARCH/bash $BIN_DIR/bash
	chmod 755 $BIN_DIR/bash
	cp -f $SAT_DIR/sat.sh $BIN_DIR/sat
	chmod 755 $BIN_DIR/sat
	
	cp -f $SAT_DIR/bin/$ARCH/simg2img $BIN_DIR/simg2img
	chmod +x $BIN_DIR/simg2img
	
	cp -f $SAT_DIR/bin/$ARCH/img2simg $BIN_DIR/img2simg
	chmod +x $BIN_DIR/img2simg
}

rewrite_file () {
	FILE="$1"
	TXT="$2"
	VAL="$3"
	
	input="$SAT_DIR/.tmpfile.txt"
	tempf="$SAT_DIR/.tmpfile2.txt"
	cp -f "$FILE" "$input"
	
	while IFS="" read -r line
	do
	case $line in
		*"$TXT"*) echo "$VAL" >> "$tempf" ;;
		*) echo "$line" >> "$tempf" ;;
	esac
	done < "$input"
	cp -f "$tempf" "$FILE"
	rm -f "$input"
	rm -f "$tempf"
}

write_config () {
	CONF_FILE="$1"
	VAR="$2"
	VALUE="$3"
	
	if [ -f "$CONF_FILE" ]
	then
		temp=`cat "$CONF_FILE" | grep "$VAR="`
		varf="${temp##*=}"
		if [ -z "$temp" ]
		then
			echo "$VAR=$VALUE" >> "$CONF_FILE"
		else
			if [ "$varf" != "$VALUE" ]
			then
				rewrite_file "$CONF_FILE" "$VAR=" "$VAR=$VALUE"
			fi
		fi
	else
		echo "$VAR=$VALUE" >> "$CONF_FILE"
	fi
}

#detect OS_TYPE ---------------------------------------------------
case $OS_TYPE in
	*Android*|*android*|*ANDROID*) OS_TYPE="Android" ;;
	*Linux*|*linux*|*LINUX*|*nix*|*NIX*)
	check=`uname -m`
	case $check in
		*arm*) OS_TYPE="Android" ;;
		*) OS_TYPE="Linux" ;;
	esac
	;;
	*) echo "unkown OS type"; echo " "; exit 1 ;;
esac

#detect architecture ----------------------------------------------
if [ "$OS_TYPE" = "Android" ]
then
	ARCH=`getprop "ro.product.cpu.abilist"`
	if [ -z "$ARCH" ]
	then
		ARCH=`getprop "ro.product.cpu.abi"`
	fi
	
	case $ARCH in
	*arm64*) ARCH="arm64" ;;
	*armeabi*) ARCH="arm" ;;
	esac
else
	case "$(uname -m)" in
	*x86_64*) ARCH="64-bit" ;;
	*) ARCH="32-bit" ;;
	esac
fi

#print config -----------------------------------------------------
echo " "
echo "OS: $OS_TYPE"
echo "Architecture: $ARCH"
echo " "

#install ----------------------------------------------------------
if [ $OS_TYPE = "Linux" ]
then
	if [ -f "$SAT_DIR/sat.sh" ]
	then
		mv $SAT_DIR/sat.sh $SAT_DIR/sat
	fi
	chmod +x $SAT_DIR/sat
	chmod +x $SAT_DIR/bin/$ARCH/simg2img $SAT_DIR/bin/$ARCH/img2simg
	
	if [ -f ~/.bashrc ]
	then	
		add_to_path "$SAT_DIR" ~/.bashrc
	elif [ -f ~/.bash_profile ]
	then
		add_to_path "$SAT_DIR" ~/.bash_profile	
	elif [ -f ~/.profile ]
	then
		add_to_path "$SAT_DIR" ~/.profile
	fi
	
else
	if [ -f "$BIN_DIR/bash" ] && [ -f "$BIN_DIR/sat" ]
	then
		if [ -x "$BIN_DIR/bash" ] && [ -x "$BIN_DIR/sat" ]
		then
			echo "No need to install"
			#exit 1
		else
			set_env "$SAT_DIR/sat.sh" "$OS_TYPE"
			install_on_android
		fi
	else
		set_env "$SAT_DIR/sat.sh" "$OS_TYPE"
		install_on_android
	fi
		
	if [ -x "$BIN_DIR/bash" ] && [ -x "$BIN_DIR/sat" ]
	then
		echo "Installation: success"
	else
		echo "Installation: failed"
	fi
	echo " "
fi

#save to config_file ----------------------------------------------
write_config "$CONFIG_FILE" "OS_TYPE" "$OS_TYPE"
write_config "$CONFIG_FILE" "ARCH" "$ARCH"
