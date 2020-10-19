#!/bin/bash

BIN_DIR="/data/local/sat"
SAT_DIR=`dirname "$(readlink -f "$0")"`
OS_TYPE=`uname -o`
CONFIG_FILE="$SAT_DIR/default.conf"
TB="unknown"
UPDATE="false" #for Android
BASH_DIR="/system/bin"

#set environment
set_env () {
	FILE="$1"
	OS_TYPE="$2"
	FIRST_LINE=`head -1 "$FILE"`
	if [[ "$FIRST_LINE" != "#!/bin/bash" && "$OS_TYPE" == "Linux" ]]
	then
		awk  -v awkvar="$FIRST_LINE" '{sub(awkvar,"#!/bin/bash")}1' "$FILE" > temp.txt && mv temp.txt "$FILE"
	fi
	
	if [[ "$FIRST_LINE" != "#!/system/bin/bash" && "$OS_TYPE" == "Android" ]]
	then
		awk  -v awkvar="$FIRST_LINE" '{sub(awkvar,"#!/system/bin/bash")}1' "$FILE" > temp.txt && mv temp.txt "$FILE" 
	fi
}

add_to_path () {
	PATH_TO_SAT='export PATH="'"$1"':$PATH"'
	if [ -z "$(cat "$2" | grep "$PATH_TO_SAT")" ]
	then
		echo " " >> "$2"
		echo "$PATH_TO_SAT" >> "$2"
		source "$2"
	fi
}

install_on_android () {
	cp -f $SAT_DIR/sat $BIN_DIR/sat
	chmod 755 $BIN_DIR/sat
	
	cp -f $SAT_DIR/bin/$ARCH/simg2img $BIN_DIR/simg2img
	chmod +x $BIN_DIR/simg2img
	
	cp -f $SAT_DIR/bin/$ARCH/img2simg $BIN_DIR/img2simg
	chmod +x $BIN_DIR/img2simg

	cp -f $SAT_DIR/bin/$ARCH/$TB $BIN_DIR/$TB
	chmod 755 $BIN_DIR/$TB
	
	cp -f $SAT_DIR/bin/tools/unzip-arm $BIN_DIR/unzip-arm
	chmod 755 $BIN_DIR/unzip-arm
	
	mkdir -p "$SAT_DIR/tmpsat"
	$BIN_DIR/unzip-arm -o "$SAT_DIR/bin/tools/bash.zip" -d "$SAT_DIR/tmpsat" &> /dev/null
	cp -f "$SAT_DIR/tmpsat/system/bin/bash" "$BASH_DIR/bash"
	cp -f "$SAT_DIR/tmpsat/system/bin/bashbug" "$BASH_DIR/bashbug"
	cp -f "$SAT_DIR/tmpsat/system/etc/bashrc" "/system/etc/bashrc"
	cp -f "$SAT_DIR/tmpsat/system/etc/bash_logout" "/system/etc/bash_logout"
	chmod 755 $BASH_DIR/bash
	chmod 755 $BASH_DIR/bashbug
	chmod 755 /system/etc/bashrc
	chmod 755 /system/etc/bash_logout
	rm -rf "$SAT_DIR/tmpsat"
}

mod_sat () {
	FILE="$SAT_DIR/sat"
	
	CONTENT="SAT_DIR=$SAT_DIR"
	awk  -v awkvar="$CONTENT" '{sub("SAT_DIR=unknown",awkvar)}1' $FILE > temp.txt && mv temp.txt $FILE
	
	CONTENT="OS_TYPE=$OS_TYPE"
	awk  -v awkvar="$CONTENT" '{sub("OS_TYPE=unknown",awkvar)}1' $FILE > temp.txt && mv temp.txt $FILE
	
	CONTENT="ARCH=$ARCH"
	awk  -v awkvar="$CONTENT" '{sub("ARCH=unknown",awkvar)}1' $FILE > temp.txt && mv temp.txt $FILE

	CONTENT="TB=$BIN_DIR/$TB"
	awk  -v awkvar="$CONTENT" '{sub("TB=unknown",awkvar)}1' $FILE > temp.txt && mv temp.txt $FILE

	CONTENT="ANDROID_BIN=$BIN_DIR"
	awk  -v awkvar="$CONTENT" '{sub("ANDROID_BIN=unknown",awkvar)}1' $FILE > temp.txt && mv temp.txt $FILE

}

#parse options ----------------------------------------------------
while [ "$#" -gt 0 ]; do
    case "$1" in
        -u|--update) UPDATE="true" ;;
        *) echo "unknown option passed"; exit 1 ;;
    esac
    shift
done

#detect OS_TYPE ---------------------------------------------------
case $OS_TYPE in
	*Android*|*android*|*ANDROID*) OS_TYPE="Android" ;;
	*Linux*|*linux*|*LINUX*|*nix*|*NIX*)
	check=`uname -m`
	case $check in
		*ar*) OS_TYPE="Android" ;;
		*) OS_TYPE="Linux" ;;
	esac
	;;
	*) echo "unkown OS type"; echo " "; exit 1 ;;
esac

#detect architecture + choose TB----------------------------------------------
if [ "$OS_TYPE" = "Android" ]
then
	ARCH=`getprop "ro.product.cpu.abilist"`
	if [ -z "$ARCH" ]
	then
		ARCH=`getprop "ro.product.cpu.abi"`
	fi
	
	case $ARCH in
	*arm64*) ARCH="arm64" ;; #arm64 will use arm bins (changed before install section)
	*armeabi*) ARCH="arm" ;;
	*) ARCH="arm" ;;
	esac

	if [ -e "/dev/loop0" ]
	then
		TB="toybox"
	else
		TB="toybox-old"
	fi

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

if [ "$ARCH" = "arm64" ]
then
	ARCH="arm"
fi

#install ----------------------------------------------------------
if [ -f "$SAT_DIR/sat.sh" ]
then
	cp -f $SAT_DIR/sat.sh $SAT_DIR/sat
	
	#setup shell directory
	set_env "$SAT_DIR/sat" "$OS_TYPE"
	
	#setup variables for sat
	mod_sat 
else
	echo "Installation: failed (sat.sh was not found)"
	exit 1
fi

if [ $OS_TYPE = "Linux" ]
then
	chmod +x $SAT_DIR/sat
	chmod +x $SAT_DIR/bin/$ARCH/simg2img $SAT_DIR/bin/$ARCH/img2simg
	
	if [ -f ~/.bashrc ]
	then	
		add_to_path "$SAT_DIR" ~/.bashrc
	elif [ -f ~/.bash_profile ]
	then
		add_to_path "$SAT_DIR" ~/.bash_profile	
	elif [ -f ~/.zshrc ]
	then
		add_to_path "$SAT_DIR" ~/.zshrc
	elif [ -f ~/.zprofile ]
	then
		add_to_path "$SAT_DIR" ~/.zprofile
	elif [ -f ~/.cshrc ]
	then
		add_to_path "$SAT_DIR" ~/.cshrc
	elif [ -f ~/.tcshrc ]
	then
		add_to_path "$SAT_DIR" ~/.tcshrc
	elif [ -f ~/.login ]
	then
		add_to_path "$SAT_DIR" ~/.login
	elif [ -f ~/.kshrc ]
	then
		add_to_path "$SAT_DIR" ~/.kshrc
	elif [ -f ~/.profile ]
	then
		add_to_path "$SAT_DIR" ~/.profile
	else
		echo '#path to SAT' > ~/.profile
		add_to_path "$SAT_DIR" ~/.profile
	fi
	
	if [ -x "$SAT_DIR/sat" ] && [ -x "$SAT_DIR/bin/$ARCH/simg2img" ] && [ -x "$SAT_DIR/bin/$ARCH/img2simg" ]
	then
		echo "Installation: success"
		echo " "
	fi
else
	mount -o rw,remount /system
	mkdir -p $BIN_DIR
	if [ -x "$BASH_DIR/bash" ] && [ -x "$BIN_DIR/sat" ] && [ -x "$BIN_DIR/simg2img" ] && [ -x "$BIN_DIR/img2simg" ] && [ -x "$BIN_DIR/$TB" ]
	then
		if [[ "$UPDATE" == "false" ]]
		then
			echo "No need to install"
			exit 1
		else
			install_on_android
		fi
	else
		install_on_android
	fi
		
	if [ -x "$BASH_DIR/bash" ] && [ -x "$BIN_DIR/sat" ] && [ -x "$BIN_DIR/simg2img" ] && [ -x "$BIN_DIR/img2simg" ] && [ -x "$BIN_DIR/$TB" ]
	then
		add_to_path "$BIN_DIR" /system/etc/mkshrc
		add_to_path "$BIN_DIR" /system/etc/bashrc
		echo "Installation: success"
	else
		echo "Installation: failed"
	fi
	echo " "
	mount -o ro,remount /system
fi
 
