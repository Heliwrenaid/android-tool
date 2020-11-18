#!/bin/bash

#SETTINGS
unpack=0
repack=0
dest_opt=0
debug=0
rl=0
ow=0 #overwriting
dm=0 #disable mounting
error_a=0 #-a and -u
error_u=0 #-u and -r in command
error_r=0 #-a and -r in command
mp=0 #change mount point dir
dis_um=0 #disable umounting for repack
print_conf_passed=0
use_tool_binaries="true"
enable_color="true"
do_resize="true"
update="false"
resize_plus="false"
resize_raw="false"
del_source="false"
no_mode=0
aonly=0
ab=0
clean=0
ml=0

#variables from installer.sh
SAT_DIR=unknown
OS_TYPE=unknown
ARCH=unknown
ANDROID_BIN=unknown
TB=unknown

start=`pwd`

config_file="$SAT_DIR/default.conf"

mount_dir="/mnt/sat/loop"
default_m_dir="/mnt/sat"
raw_dir="$start/system.raw_img"
sparse_dir="NOT_SPECIFIED"

#---FUNCTIONS---
my_print () {
	txt="$1"
	if [[ $enable_color == "true" ]]
	then
		while [[ "$#" -gt 0 ]]; do
			case "$1" in
		        black) printf "\e[30m";;
		        red) printf "\e[31m";;
		        green) printf "\e[32m";;
		        yellow) printf "\e[33m";;
		        blue) printf "\e[34m";;
		       magenta) printf "\e[35m";;
		        cyan) printf "\e[36m";;
		        white) printf "\e[37m";;
		        bold) printf "\e[1m";;
		        faint) printf "\e[2m";;
		        italic) printf "\e[3m";;
		        underlined) printf "\e[4m";;
		        -source) printf "\e[33;1m";;
		        -raw) printf "\e[35;1m";;
		        -mount) printf "\e[36;1m";;
		        -sparse) printf "\e[34;1m";;
			esac
			shift
		done
		printf "$txt"
		printf "\e[0m"
	else
		printf "$txt"
	fi
}

#finding alternative name/dir
free_name () {
	tmp="$1"
	if [[ $tmp == /* ]]
	then
		dir=${tmp%/*}
		tmp1=${tmp##*/}
		name=${tmp1%.*}
		ext=${tmp1##*.}
	else
		dir="$start"
		name=${tmp%.*}
		ext=${tmp##*.}
	fi
	iter=1
	new_x="$dir/$name-$iter.$ext"
	while [[ -f "$new_x" ]]
	do
		iter=$(( $iter + 1 ))
		new_x="$dir/$name-$iter.$ext"
	done
	echo "$new_x"
}

print_config () {
	if [[ $print_conf_passed == 0 ]]
	then
		if [[ $1 == "unpack" ]]
		then
			my_print "\n*** UNPACK SETTINGS ***\n" green bold underlined
			my_print "SPARSE_IMG = $source_dir\n" yellow bold
			my_print "RAW_IMG = $raw_dir\n" magenta bold
			my_print "M_DIR = $mount_dir\n\n" cyan bold
		fi
		
		if [[ $1 == "repack" ]]
		then
			my_print "\n*** REPACK && NO-MODE SETTINGS ***\n" green bold underlined
			my_print "RAW_IMG = $raw_dir\n" magenta bold
			my_print "M_DIR = $mount_dir\n" cyan bold
			my_print "F_SPARSE_IMG = $sparse_dir\n\n" blue bold
			print_conf_passed=1
		fi
	fi
	
	source_dir_cp="${source_dir##*/}"
	raw_dir_cp="${raw_dir##*/}"
	sparse_dir_cp="${sparse_dir##*/}"
}

raw_to_loop () {
	RAW="$1"
	if [[ -f "$SAT_DIR/.loop.info" ]]
	then
		tmp=`cat $SAT_DIR/.loop.info | grep ";$RAW!"`
		if [[ -n "$tmp" ]]
		then
			LOOP="${tmp%%:*}"
		else
			LOOP="unknown"
		fi
	else
		LOOP="unknown"
	fi
	echo "$LOOP"
}

resize_p () {
	RAW="$1"
	SIZE="$2"
	
	e2fsck -fy $RAW &> /dev/null
	resize2fs -M $RAW &> /dev/null
	
	RAW_SIZE=`du -m $RAW | awk '{ print $1 }'`
	RAW_SIZE=$(( $RAW_SIZE + $SIZE ))
	e2fsck -fy $RAW &> /dev/null
	my_print "\nResizing "; my_print "${RAW##*/}" -raw; my_print " to "; my_print "$RAW_SIZE MB\n" green bold; my_print "..."
	resize2fs -f $RAW $RAW_SIZE'M' &> /dev/null
	my_print " Done\n\n"
}

#load config
if [[ -f $config_file ]]
then
	color=`cat $config_file | grep "enable_color="`
	binaries=`cat $config_file | grep "use_tool_binaries="`
	resize=`cat $config_file | grep "do_resize="`
	m_dir=`cat $config_file | grep "M_DIR="`
	def_m_dir=`cat $config_file | grep "m_mount_dir="`
	os_type=`cat $config_file | grep "OS_TYPE="`
	arch=`cat $config_file | grep "ARCH="`
	sat_dir=`cat $config_file | grep "SAT_DIR="`
	toy=`cat $config_file | grep "TB="`
	andr_bin=`cat $config_file | grep "ANDROID_BIN="`
	
	
	if [[ "$color" != "" ]]
	then
		enable_color="${color##*=}"
	fi
	if [[ "$binaries" != "" && "$OS_TYPE" == "Linux" ]]
	then
		use_tool_binaries="${binaries##*=}"
	fi
	if [[ "$resize" != "" ]]
	then
		do_resize="${resize##*=}"
	fi
	if [[ "$m_dir" != "" ]]
	then
		mount_dir="${m_dir##*=}"
	fi
	if [[ "$def_m_dir" != "" ]]
	then
		default_m_dir="${def_m_dir##*=}"
	fi
	if [[ "$os_type" != "" ]]
	then
		OS_TYPE="${os_type##*=}"
	fi
	if [[ "$arch" != "" ]]
	then
		ARCH="${arch##*=}"
	fi
	if [[ "$sat_dir" != "" ]]
	then
		SAT_DIR="${sat_dir##*=}"
	fi
		if [[ "$toy" != "" ]]
	then
		TB="${toy##*=}"
	fi
		if [[ "$andr_bin" != "" ]]
	then
		ANDROID_BIN="${andr_bin##*=}"
	fi
else
	my_print "!!! Configuration file ($config_file) was not found ..." yellow bold
fi

#actions if neccesery values is unknown
if [[ "$SAT_DIR" == "unknown" ]]
then
	my_print "\n\nUnable to find SAT main directory\n" red bold
	my_print "Please run install.sh again ...\n" red bold
	my_print "or\n" red bold
	my_print "add SAT_DIR=/path/to/sat to ${config_file##*/}\n\n" red bold
	exit 1
fi

if [[ "$OS_TYPE" == "unknown" ]]
then
	my_print "\n\nOS type is not specifed\n" red bold
	my_print "Please run install.sh again ...\n" red bold
	my_print "or\n" red bold
	my_print "add OS_TYPE=Linux (or Android) to $config_file\n\n" red bold
	exit 1
fi

if [[ "$ARCH" == "unknown" ]]
then
	my_print "\n\nDevice architecture is not detected\n" red bold
	my_print "Please run install.sh again ...\n" red bold
	my_print "or\n" red bold
	my_print "add ARCH=VAL to $config_file ... \n" red bold
	my_print "...where VAL can be one of values: 32-bit,64-bit (for Linux) and arm,arm64 (for Android) \n\n" red bold
	exit 1
fi

if [[ "$TB" == "unknown" ]]
then
	use_tool_binaries="false"
	my_print "\n\n!!! Can't detect toybox ... Mounting files can not work\n\n" red bold
fi

if [[ "$ANDROID_BIN" == "unknown" ]]
then
	use_tool_binaries="false"
	my_print "\n\n!!! Can't detect binaries ... trying some workarounds\n" red bold
	my_print "Also try to run install.sh again ...\n\n" red bold
fi


#choose options according to OS
if [[ "$OS_TYPE" == "Linux" ]]
then
	BIN_DIR="$SAT_DIR/bin/$ARCH"
else
	BIN_DIR="$ANDROID_BIN"
fi

#parse options
declare -a dargs=()
read_d_args()
{
    while (($#)) && [[ $1 != -* ]]; do dargs+=("$1"); shift; done
}
declare -a vndks=()
read_vndks()
{
    while (($#)) && [[ $1 != -* ]]; do vndks+=("$1"); shift; done
}
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -vndk) read_vndks "${@:2}" ; vndks_len=${#vndks[@]} ;;
        -a|--auto) read_d_args "${@:2}" ; error_a=1 ; unpack=1; repack=1 ; rl=1 ;;
        -u|--unpack) read_d_args "${@:2}" ; error_u=1 ; unpack=1 ;;
        -r|--repack) read_d_args "${@:2}" ; error_r=1 ; repack=1 ;;
        -o|--overwrite) ow=1 ;;
        -ab2a) aonly=1 ;;
        -debug) debug=1 ;;
        -dm) dm=1 ;;
        -m|--mount) m="$2"; shift ; mp=1 ;;
        -ml) ml=1 ; no_mode=1 ;;
        -c|--clean) clean=1 ; no_mode=1 ;;
        -dc) enable_color="false" ;;
        -resizeoff) do_resize="false" ;;
        -update) update="true" ;;
        -free) size="$2"; shift; resize_plus="true" ;;
        -ds) del_source="true" ;;
        #-freeraw) size="$3"; dest_raw="$2"; shift ; resize_raw="true" ;;
        #-h) printf "-h\n" ;;
    esac
    shift
done

if [[ $repack == 1 ]]
then
	if [[ "${dargs[0]}" == '' ]]
	then
		rl=1 ; repack=1 ; #repack last unpacked raw image 
	fi
fi
	
if [[ "${dargs[0]}" != '' ]]
then
	if [[ $repack == 1 ]]
	then
		if [[ $unpack == 1 ]]
		then
			source_dir="${dargs[0]}"
		else
			raw_dir="${dargs[0]}"
		fi
	fi
	
	if [[ $unpack == 1 ]]
	then	
		source_dir="${dargs[0]}"
	fi
fi

if [[ "${dargs[1]}" != '' ]]
then
	#change destination for unpack/repack/auto
	dest="${dargs[1]}"
	dest_opt=1
fi

#check sense of flags
if [[ $error_u == 1 && $repack == 1 ]]
then
	my_print "If u want to unpack and repack use -a option\n"
	exit 1;
fi
if [[ $error_u == 1 && $error_a == 1 ]]
then
	my_print "Choosed options have no sense (-a with -u)\n"
	exit 1;
fi
if [[ $error_u == 1 && $error_r == 1 ]]
then
	my_print "Choosed options have no sense (-a with -r)\n"
	exit 1;
fi
if [[ $error_u == 1 && $clean == 1 ]] || [[ $error_r == 1 && $clean == 1 ]] || [[ $error_a == 1 && $clean == 1 ]]
then
	my_print "You can't use -c with -a, -u, -r\n"
	exit 1;
fi
if [[ $error_u == 1 && $ml == 1 ]] || [[ $error_r == 1 && $ml == 1 ]] || [[ $error_a == 1 && $ml == 1 ]]
then
	my_print "You can't use -ml with -a, -u, -r\n"
	exit 1;
fi
if [[ $error_u == 1 && $update == "true" ]] || [[ $error_r == 1 && $update == "true" ]] || [[ $error_a == 1 && $update == "true" ]]
then
	my_print "You can't use --update with -a, -u, -r\n"
	exit 1;
fi
if [[ $resize_plus == "true" ]] && [[ -z $size ]]
then
	my_print "No size was specified\n" red bold
	exit 1
fi

#update section
if [[ $update == "true" ]]
then
	update_dir="$SAT_DIR/sat-update"
	mkdir -p "$update_dir"
	cd "$update_dir"
	
	version_now=`cat "$SAT_DIR/.version"`
	version_up=`curl https://raw.githubusercontent.com/SoulHunter24/android-tool/master/.version`
	
	if [[ "$version_up" > "$version_now" ]]
	then
		my_print "Newer version available\n" green bold
		my_print "Downloading resources\n ..." green bold
		git clone -b master https://github.com/SoulHunter24/android-tool.git &> /dev/null
		my_print "Done\n" green bold
		rm -rf android-tool/.git
		if [[ -f "$config_file" ]]
		then
			rm -f "android-tool/default.conf"
			mv -f "config_file" "android-tool/default.conf"
		fi
		cp -r android-tool/* "$SAT_DIR/"
		cp -r android-tool/.version "$SAT_DIR/"
	else
		my_print "Nothing to upgrade. It's the newest version [v$version_now]\n" yellow bold
		exit 1
	fi
	cd "$SAT_DIR"
	rm -rf "$update_dir"
	
	chmod +x install.sh
	if [[ "$SAT_DIR" == "Linux" ]]
	then
		./install.sh -rev1 -linux &> /dev/null
	else
        su
		sh install.sh -rev1 -android &> /dev/null
	fi
	
	my_print "Tool was upgraded to v$version_up\n" bold green
	exit 1
fi

#check root access
root=`id -u`
if [[ $root -ne 0 ]]
then
	my_print "*** Some functionality will not work without root access\n" red bold
fi

#--- UNPACK CONFIG ---

if [[ $unpack == 1 ]]
then

	#source_dir exists? + default raw_dir, sparse_dir
	if [[ -f "$source_dir" ]]
	then
		raw_dir="${source_dir%.img}.raw_img"
		tmp="${source_dir##*/}"
		sparse_dir="${tmp%.img}-modSH24.img"
		my_print "\n$source_dir was found ... \n"
	else
		my_print "\n*** ERROR 404: $source_dir was not found !!!\n" red
		exit 1
	fi
	
	# -d : configure
	if [[ $dest_opt == 1 ]]
	then
		if [[ $repack == 1 ]] #for auto
		then
			sparse_dir="$dest"
		else
			raw_dir="$dest"
		fi
	fi
	
	#raw_dir and source_dir full path
	if [[ $raw_dir != /* ]]
	then
		raw_dir="$start/$raw_dir"
	fi
	if [[ $source_dir != /* ]]
	then
		source_dir="$start/$source_dir"
	fi
	#raw_dir : overwriting
	if [[ -f "$raw_dir" ]]
	then
		if [[ $ow == 1 ]]
		then
			my_print "*** $raw_dir will be overwrited\n"
		else
			my_print "\n*** WARNING : $raw_dir exists ... \n" red bold
			my_print "Do you want to overwrite this file ? (y/n) : " red bold
			read opt
			if [[ "$opt" != "y" ]]
			then
				raw_dir="$(free_name $raw_dir)"
			fi
			printf "\n"
		fi
	fi
	
	# -m : configure
	if [[ $mp == 1 ]]
	then
		if [[ $m == /* ]]
		then
			mount_dir="$m"
		else
			mount_dir="$default_m_dir/$m"
		fi
	fi
	
	#mount_dir : configure
	raw_dir_copy="$raw_dir"
	if [[ "$OS_TYPE" == "Android" ]]
	then
		raw_dir="$(raw_to_loop $raw_dir)"
	fi
	
	tmp1=`mount | grep -F "$raw_dir on" | wc -l`
	if [[ $tmp1 != 0 ]]
	then
		tmp1=`mount | grep -F "$raw_dir on"`
		temp=${tmp1##*on }
		temp2=${temp% type*}
		umount "$temp2"
	fi
	
	tmp=`mount | grep -F " $mount_dir " | wc -l`
	if [[ $tmp != 0 ]]
	then
		my_print "*** $mount_dir is busy\n"
		j=0
		while [[ $tmp != 0 ]]
		do
			j=$(( $j + 1 ))
			new_mount_dir="$mount_dir-$j"
			tmp=`mount | grep -F " $new_mount_dir " | wc -l`
		done
		mount_dir="$new_mount_dir"
	fi
	raw_dir="$raw_dir_copy"
	my_print "*** $raw_dir will be mounted in $mount_dir\n"

	#print unpack config
	print_config "unpack"

	#unpacking & mounting
	my_print "unpacking "; my_print "$source_dir_cp" -source; printf " to "; my_print "$raw_dir_cp \n" -raw; my_print "..."
	if [[ $use_tool_binaries == "true" ]]
	then
		$BIN_DIR/simg2img $source_dir $raw_dir
	else
		simg2img $source_dir $raw_dir
	fi
	my_print " Done\n"
	
	#increase raw_dir
	if [[ "$resize_plus" == "true" ]]
	then
		resize_p $raw_dir $size
		resize_plus="false"
	fi
	
	if [[ $dm == 0 ]]
	then
		my_print "mounting "; my_print "$raw_dir_cp" -raw; printf " to "; my_print "$mount_dir \n" -mount; my_print "..."
		mkdir -p $mount_dir
		if [[ "$OS_TYPE" == "Android" ]]
		then
			LOOP=`"$TB" losetup -sf $raw_dir`
			mount -t ext4 "$LOOP" $mount_dir
		else
			mount $raw_dir $mount_dir
		fi
		my_print " Done\n"
	fi
	
	#save info
	echo "$raw_dir" > "$SAT_DIR/.last.info"
	if [[ ! -f "$SAT_DIR/.mount.info" ]]
	then
		touch "$SAT_DIR/.mount.info"
	fi
	mou_inf=`cat $SAT_DIR/.mount.info | grep ":$mount_dir;" | wc -l`
	if [[ $mou_inf == 0 ]]
	then
		echo "$raw_dir:$mount_dir;" >> "$SAT_DIR/.mount.info"
	fi
	
	#save info for Android
	if [[ ! -f "$SAT_DIR/.loop.info" ]]
	then
		touch "$SAT_DIR/.loop.info"
	fi
	loop_inf=`cat $SAT_DIR/.loop.info | grep ":$mount_dir;" | wc -l`
	if [[ $loop_inf == 0 ]]
	then
		echo "$LOOP:$mount_dir;$raw_dir!" >> "$SAT_DIR/.loop.info"
	fi
	
	#delete source_dir
	if [[ "$del_source" == "true" ]] && [[ -e $raw_dir ]] && [[ -s $raw_dir ]]
	then
		my_print "\nDeleting "; my_print "$source_dir_cp" -source
		rm -f $source_dir
		my_print "\n...Done\n"
	fi
fi


#---------NO MODE AND REPACK------

# some repack and no-mode config

#raw_dir : full path
if [[ $raw_dir != /* ]]
	then
		raw_dir="$start/$raw_dir"
	fi

if [[ $repack == 1 ]]
then
	
	#-rl : configure
	if [[ $rl == 1 ]]
	then
		last=`cat $SAT_DIR/.last.info`
		raw_dir="$last"
	fi
	
	#raw_dir : check
	if ! [[ -s "$raw_dir" ]]
	then
		my_print "*** File is empty\n" red bold
		exit 1
	fi
		
	if [[ -f "$raw_dir" ]]
	then
		my_print "\n$raw_dir was found ... \n"
	else
		my_print "\n*** ERROR 404: $raw_dir was not found !!!\n" red bold
		exit 1
	fi
	
	#detecting mounpoint
	raw_dir_copy="$raw_dir"
	if [[ "$OS_TYPE" == "Android" ]]
	then
		raw_dir="$(raw_to_loop $raw_dir)"
	fi
	tmp=`mount | grep "$raw_dir " | wc -l`
	if [[ $tmp != 0 ]]
	then
		tmp1=`mount | grep "$raw_dir "`
		temp=${tmp1##*on }
		temp2=${temp% type*}
		mount_dir="$temp2"
	else
		my_print "*** $raw_dir_copy is not mounted\n"
		dis_um=1
	fi
	raw_dir="$raw_dir_copy"
	
	#sparse_dir : setting name + -d : config
	if [[ $dest_opt == 1 ]]
	then
		sparse_dir="$dest"
	else
		tmp="${raw_dir##*/}"
		sparse_dir="${tmp%.raw_img}-mod.img"
		#raw_dir : full path
	fi
	if [[ $sparse_dir != /* ]]
	then
		sparse_dir="$start/$sparse_dir"
	fi
	
	#sparse_dir : overwrite
	if [[ -f "$sparse_dir" ]]
	then
		if [[ $ow == 1 ]]
		then
			my_print "*** $sparse_dir will be overwrited\n"
		else
			my_print "\n*** WARNING : $sparse_dir exists ... \n" red bold
			my_print "Do you want to overwrite this file ? (y/n) : " red bold
			read opt
			if [[ "$opt" != "y" ]]
			then
				sparse_dir="$(free_name $sparse_dir)"
			fi
		fi
	fi
fi


#detecting mountpoint --- for no mode
if [[ $repack == 0 ]]
then
	if [[ "$vndks_len" -ne 0 || $aonly == 1 ]]
	then
		if [[ $mp == 0 ]]
		then
			last=`cat $SAT_DIR/.last.info`
			raw_dir="$last"
			
			#detecting mounpoint
			raw_dir_copy="$raw_dir"
			if [[ "$OS_TYPE" == "Android" ]]
			then
				raw_dir="$(raw_to_loop $raw_dir)"
			fi
			
			tmp=`mount | grep "$raw_dir " | wc -l`
			if [[ $tmp != 0 ]]
			then
				tmp1=`mount | grep "$raw_dir "`
				temp=${tmp1##*on }
				temp2=${temp% type*}
				mount_dir="$temp2"
			fi
			raw_dir="$raw_dir_copy"
		fi
	fi
fi

# -m : configure !!! use if auto-detect works bad --- for repack and no-mode
if [[ $mp == 1 ]]
then
	if [[ $m == /* ]]
	then
		mount_dir="$m"
	else
		mount_dir="$default_m_dir/$m"
	fi
fi

#mount_dir : check
mocmd=`mount | grep "$mount_dir" | wc -l`
if [[ $mocmd == 0 && $dis_um == 0 ]]
then
	if [[ $dis_um == 0 && $no_mode == 0 ]]
	then
		my_print "Nothing mounted on $mount_dir\n"
		exit 1
	fi
fi

#detecting system arch
if [[ -d "$mount_dir/system" ]] && [[ ! -z "$(ls -A $mount_dir/system)" ]]
then
	ab=1
fi

#print config
if [[ $no_mode == 0 ]]
then
	if [[ $unpack == 0 ]] || [[ $unpack == 1 && $repack == 1 ]]
	then
		print_config "repack"
	fi
fi

#converting to a-only
if [[ $aonly == 1 ]]
then
	if [[ $ab == 1 ]]
	then
		my_print "Converting ab to a-only architecture\n..."
		cd "$mount_dir"
		ls | grep -v system | xargs rm -rf
		mv -f system/* "$mount_dir/"
		rm -rf "$mount_dir/system"
		
		cp -rf "$SAT_DIR/files/etc" "$mount_dir"
		cd "$mount_dir/etc/init"
		chmod 644 apex-setup.rc
		chmod 644 init.treble-environ.rc
		chmod 644 mediaswcodec-treble.rc
		chmod 755 zygote
		cd zygote
		chmod 644 *.rc
		my_print " Done\n"
		ab=0
		cd "$start"
	else
		my_print "*** Hmm...it isn't AB system, no need to convert\n\n" yellow bold
	fi
fi

#deleting vndk
if [[ $vndks_len -ne 0 ]]
then
	my_print "deleting vndk folders on "; my_print "$mount_dir\n" -mount; printf "..."
	if [[ $ab == 1 ]]
	then
		cd "$mount_dir/system"
	else
		cd "$mount_dir"
	fi
	i="$vndks_len"
	while [[ "$i" -ge 0 ]]; do
		rm -rf "lib/vndk-${vndks[$i]}"
		rm -rf "lib/vndk-sp-${vndks[$i]}"
		rm -rf "lib64/vndk-${vndks[$i]}"
		rm -rf "lib64/vndk-sp-${vndks[$i]}"
		i=$[i-1]
	done
	my_print " Done\n"
fi

#repacking	
if [[ $repack == 1 ]]
then
	cd "$start"
	
	#for Android: losetup --detach LOOP
	if [[ "$OS_TYPE" == "Android" ]]
	then
		loop_inf=`cat $SAT_DIR/.loop.info | grep ":$mount_dir;" | wc -l`
		if [[ "$loop_inf" != 0 ]]
		then
			loop_inf=`cat $SAT_DIR/.loop.info | grep ":$mount_dir;"`
			tmp="${loop_inf%%:*}"
			"$TB" losetup -d $tmp
			
			grep -v ":$tmp;" "$SAT_DIR/.loop.info" > temp.inf
			mv -f temp.inf "$SAT_DIR/.loop.info"
		fi
	fi
	if [[ $debug == 1 ]]
	then
		if [[ $dis_um == 0 ]]
		then
			my_print "unmounting "; my_print "$mount_dir \n" -mount
			umount $mount_dir
			rm -rf $mount_dir
		fi
		if [[ $do_resize == "true" ]]
		then
			e2fsck -fy $raw_dir
			resize2fs -M $raw_dir
		fi
	else
		if [[ $dis_um == 0 ]]
		then
			my_print "unmounting "; my_print "$mount_dir \n" -mount
			umount $mount_dir &> /dev/null
			rm -rf $mount_dir &> /dev/null
		fi
		if [[ $do_resize == "true" ]]
		then
			e2fsck -fy $raw_dir &> /dev/null
			resize2fs -M $raw_dir &> /dev/null
		fi
	fi
			

	my_print "repacking "; my_print "$raw_dir_cp" -raw; printf " to "; my_print "$sparse_dir_cp \n" -sparse; my_print "..."
	if [[ $use_tool_binaries == "true" ]]
	then
		$BIN_DIR/img2simg $raw_dir $sparse_dir
	else
		img2simg $raw_dir $sparse_dir
	fi
	my_print " Done\n"
	
fi

#mountlist
if [[ $ml == 1 ]]
then
	if [[ -f "$SAT_DIR/.mount.info" ]]
	then
		cp "$SAT_DIR/.mount.info" .tmpfile.txt
		
		input=".tmpfile.txt"
		echo "tmpfile2" > .tmpfile2.txt
		while IFS= read -r line
		do
			raw="${line%%:*}"
			
			raw_dir_copy="$raw"
			if [[ "$OS_TYPE" == "Android" ]]
			then
				raw="$(raw_to_loop $raw)"
			fi
			
			tmp1=`mount | grep "$raw "`
			check=`cat .tmpfile2.txt | grep "$tmp1" | wc -l`
			if [[ $check == 0 ]]
			then
				if [[ "$OS_TYPE" == "Android" ]]
				then
					my_print "${raw_dir_copy##*/}: $tmp1\n" green bold
				else
					my_print "$tmp1\n" green bold
				fi
			fi
			echo "$tmp1" >> .tmpfile2.txt
		done < "$input"
		
		rm -rf .tmpfile.txt
		rm -rf .tmpfile2.txt
	else
		my_print "Nothing is mounted\n" red bold
	fi
fi


if [[ $clean == 1 ]]
then
	if [[ ! -f "$SAT_DIR/.mount.info" ]]
	then
		my_print "*** There is nothing to remove\n" red
		exit 1
	fi
	my_print "*** Unmount and delete M_DIR's + clear SAT history\n..."
	j=`cat "$SAT_DIR/.mount.info" | wc -l`
	while [ $j -ne 0 ]
	do
		str=`sed -n 1p "$SAT_DIR/.mount.info"`
		m="${str#*:}"
		mpd="${m%?}"
		umount "$mpd" &> /dev/null
		rm -rf "$mpd"
		grep -v ":$mpd;" "$SAT_DIR/.mount.info" > temp
		mv temp "$SAT_DIR/.mount.info"
		j=$(( $j - 1 ))
	done
	
	j=`cat "$SAT_DIR/.mount.info" | wc -l`
	while [ $j -ne 0 ]
	do
		str=`sed -n 1p "$SAT_DIR/.mount.info"`
		r=${str%:}
		i=`mount | grep "$r " | wc -l`
		
		while [ $i -ne 0 ]
		do
			str=`sed -n 1p "$SAT_DIR/.mount.info"`
			NAME=${str##*on }
			mpd=${NAME% type*}
			umount "$mpd" &> /dev/null
			rm -rf "$mpd"
			grep -v ":$mpd;" "$SAT_DIR/.mount.info" > temp
			mv temp "$SAT_DIR/.mount.info"
			i=$(( $i - 1 ))
		done
		
		grep -v "$m" "$SAT_DIR/.mount.info" > temp
		mv temp "$SAT_DIR/.mount.info"
		j=$(( $j - 1 ))
	done
	
	rm -rf "$default_m_dir"
	rm -f "$SAT_DIR/.mount.info"
	rm -f "$SAT_DIR/.last.info"
	if [[ -e "$SAT_DIR/.loop.info" ]]
	then
		rm -f "$SAT_DIR/.loop.info"
	fi
	my_print " Done\n"
fi
 
