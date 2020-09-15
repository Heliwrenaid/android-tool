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
enable_color="true"
use_tool_binaries="true"
do_resize="true"
update="false"
no_mode=0
aonly=0
ab=0
clean=0
ml=0
start=`pwd`

config_file="default.conf"

mount_dir="/mnt/sat/loop"
default_m_dir="/mnt/sat"
raw_dir="$start/system.raw_img"
sparse_dir="NOT_SPECIFIED"


#load config
if [[ -f $config_file ]]
then
	color=`cat $config_file | grep "enable_color"`
	binaries=`cat $config_file | grep "use_tool_binaries"`
	resize=`cat $config_file | grep "do_resize"`
	m_dir=`cat $config_file | grep "M_DIR"`
	def_m_dir=`cat $config_file | grep "m_mount_dir"`
	
	if [[ "$color" != "" ]]
	then
		enable_color="${color##*=}"
	fi
	if [[ "$binaries" != "" ]]
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
fi

#---FUNCTIONS---

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
	new_x="$dir/$name($iter).$ext"
	while [[ -f "$new_x" ]]
	do
		iter=$(( $iter + 1 ))
		new_x="$dir/$name($iter).$ext"
	done
	echo "$new_x"
}

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
        -aonly) aonly=1 ;;
        --debug) debug=1 ;;
        -dm) dm=1 ;;
        -m|--mount) m="$2"; shift ; mp=1 ;;
        -ml) ml=1 ; no_mode=1 ;;
        -c|--clean) clean=1 ; no_mode=1 ;;
        -dc) enable_color="false" ;;
        --resize) do_resize="true" ;;
        --install) chmod u+x bin/simg2img; chmod u+x bin/img2simg; exit 1;;
        --update) update="true" ;;
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

#update section
if [[ $update == "true" ]]
then
	update_dir="/home/sat-update"
	mkdir -p "$update_dir"
	cd "$update_dir"
	git clone -b testing https://github.com/SoulHunter24/android-tool.git
	version_now=`cat "$start/.version"`
	version_up=`cat "android-tool/.version"`
	if [[ "$version_up" > "$version_now" ]]
	then
		rm -rf android-tool/.git
		if [[ -f "$start/$config_file" ]]
		then
			rm -f "android-tool/$config_file"
			mv -f "$start/$config_file" "android-tool/$config_file"
		fi
		cp -r android-tool/* "$start/"
		cp -r android-tool/.version "$start/"
		rm -rf "$update_dir"
		my_print "Tool was upgraded to v$version_up\n" bold green
	else
		my_print "It's the newest version [v$version_now]\n" yellow bold
	fi
	exit 1
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
	my_print "*** $raw_dir will be mounted in $mount_dir\n"

	#print unpack config
	print_config "unpack"

	#unpacking & mounting
	my_print "unpacking "; my_print "$source_dir_cp" -source; printf " to "; my_print "$raw_dir_cp \n" -raw; my_print "..."
	if [[ $use_tool_binaries == "true" ]]
	then
		./bin/simg2img $source_dir $raw_dir
	else
		simg2img $source_dir $raw_dir
	fi
	my_print " Done\n"
	if [[ $dm == 0 ]]
	then
		my_print "mounting "; my_print "$raw_dir_cp" -raw; printf " to "; my_print "$mount_dir \n" -mount; my_print "..."
		mkdir -p $mount_dir
		mount $raw_dir $mount_dir
		my_print " Done\n"
	fi
	
	#save info
	echo "$raw_dir" > .last.info
	if [[ ! -f .mount.info ]]
	then
		touch .mount.info
	fi
	mou_inf=`cat .mount.info | grep ":$mount_dir;" | wc -l`
	if [[ $mou_inf == 0 ]]
	then
		echo "$raw_dir:$mount_dir;" >> .mount.info
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
		last=`cat .last.info`
		raw_dir="$last"
		#printf "$mount_dir\n"
	fi
	
	#raw_dir : check
	if ! [[ -s "$raw_dir" ]]
	then
		my_print "*** File is empty\n"
		exit 1
	fi
		
	if [[ -f "$raw_dir" ]]
	then
		my_print "\n$raw_dir was found ... \n"
	else
		my_print "\n*** ERROR 404: $raw_dir was not found !!!\n"
		exit 1
	fi
	
	#detecting mounpoint
	tmp=`mount | grep "$raw_dir " | wc -l`
	if [[ tmp != 0 ]]
	then
		tmp1=`mount | grep "$raw_dir "`
		temp=${tmp1##*on }
		temp2=${temp% type*}
		mount_dir="$temp2"
	else
		my_print "*** $raw_dir is not mounted\n"
		dis_um=1
	fi
	
	#sparse_dir : setting name + -d : config
	if [[ $dest_opt == 1 ]]
	then
		sparse_dir="$dest"
	else
		tmp="${raw_dir##*/}"
		#czasem moze nie byc .raw_img sprawdzic czy po tym sa sobie rowne
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
			last=`cat .last.info`
			raw_dir="$last"
			#detecting mounpoint
			tmp=`mount | grep "$raw_dir " | wc -l`
			if [[ $tmp != 0 ]]
			then
				tmp1=`mount | grep "$raw_dir "`
				temp=${tmp1##*on }
				temp2=${temp% type*}
				mount_dir="$temp2"
			fi
		fi
	fi
fi

# zero sprawdzania poprawnosci
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

#coverting to a-only
if [[ $aonly == 1 ]]
then
	if [[ $ab == 1 ]]
	then
		my_print "Converting ab to a-only architecture\n..."
		cd "$mount_dir"
		ls | grep -v system | xargs rm -rf
		mv -f system/* "$mount_dir/"
		rm -rf "$mount_dir/system"
		
		cp -rf "$start/files/etc" "$mount_dir"
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
		./bin/img2simg $raw_dir $sparse_dir
	else
		img2simg $raw_dir $sparse_dir
	fi
	my_print " Done\n"
	
fi

#mountlist
if [[ $ml == 1 ]]
then
	if [[ -f .mount.info ]]
	then
		cp .mount.info .tmpfile.txt
		
		input=".tmpfile.txt"
		echo "tmpfile2" > .tmpfile2.txt
		while IFS= read -r line
		do
			raw="${line%%:*}"
			tmp1=`mount | grep "$raw "`
			check=`cat .tmpfile2.txt | grep "$tmp1" | wc -l`
			if [[ $check == 0 ]]
			then
				my_print "$tmp1\n" green bold
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
	if [[ ! -f .mount.info ]]
	then
		my_print "*** There is nothing to remove\n" red
		exit 1
	fi
	my_print "*** Unmounting and deleting mountpoints folders\n..."
	j=`cat .mount.info | wc -l`
	while [ $j -ne 0 ]
	do
		str=`sed -n 1p .mount.info`
		m="${str#*:}"
		mpd="${m%?}"
		umount "$mpd"
		rm -rf "$mpd"
		grep -v ":$mpd;" .mount.info > temp
		mv temp .mount.info
		j=$(( $j - 1 ))
	done
	
	j=`cat .mount.info | wc -l`
	while [ $j -ne 0 ]
	do
		str=`sed -n 1p .mount.info`
		r=${str%:}
		i=`mount | grep "$r " | wc -l`
		
		while [ $i -ne 0 ]
		do
			str=`sed -n 1p .mount.info`
			NAME=${str##*on }
			mpd=${NAME% type*}
			umount "$mpd"
			rm -rf "$mpd"
			grep -v ":$mpd;" .mount.info > temp
			mv temp .mount.info
			i=$(( $i - 1 ))
		done
		
		grep -v "$m" .mount.info > temp
		mv temp .mount.info
		j=$(( $j - 1 ))
	done
	
	rm -rf "$default_m_dir"
	rm -rf .mount.info
	my_print " Done\n"
fi
