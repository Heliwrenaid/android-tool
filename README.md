# About the project

SAT is a script created for unpack/repack image files (especially Generic System Images). It is available on Linux and Android devices. The main aim of SAT is to make some steps simple and automatically. It also contains some features related to GSIs:

- reduce size of system image file
- convert system from AB architecture to A-only

**Features for unpack/repack**
* automatically creating names for output files/directories
* prompt warning before overwriting files
* finding alternative names if file/directory exists
* automatically creating and mounting mount points
* option for umount and delete all mount points created by SAT
* colored UI
* printing information of mounted files
* many options for set names of output files, mount points, etc.
* resizing file to minimum size
* enlarge file in order to set a free space after mounting it
* and many more ...

# Requirements

**--- Linux ---**\
From version 2.0 all neccessery binaries are pre-builded, so you don't have to install it manually.

**--- Android ---**\
In order to use SAT on Android device you must have:
* rooted phone
* installed busybox (if you haven't it, just download any busybox installer apk eg. from Google Playstore)
* terminal emulator (recommended [Termux])

# Installation

**--- Linux ---**\
<br>
**I. Download**\
In terminal:
```
$ git clone https://github.com/SoulHunter24/android-tool.git
```
**or**\
<br>
download and unpack archive from **[releases]**

**II. Run installation script**\
In terminal:
```
$ cd /path/to/sat/directory
$ chmod +x install.sh
$ ./install.sh
```
The script will detect your system OS and architecture automatically.\

**Note:** If SAT can't run after installation then close and open terminal again.\

**--- Android ---**\
<br>
There are two options for installing SAT on Android:\
**(1)** using terminal emulator\
**(2)** using TWRP

**(1) Terminal**\
I. Download and unpack archive from **[releases]**\
II. Open terminal and run:
```
$ cd /path/to/sat/directory
$ su
# chmod +x install.sh
# sh install.sh
```
**Note:** If SAT can't run after installation then close and open terminal again or type "exit" and then "su".\

**(2) TWRP**\
Just download the special archive from **[releases]** and flash it in TWRP.

# Usage
SAT has basiclly 4 modes (auto, unpack, repack, no-mode). In each mode you can use some addiotional options (possible to use few options in one command). To use SAT you must run it in terminal with root access (needed to mount files):
```
$ su
# sat <OPTIONS>
```
**See a full documentation [here]**

# Update

**--- Linux ---**\

To update SAT run below command:
```
$ sat -update
```
It will do everything automatically and keeps your settings in "default.conf" file.\

**--- Android ---**\

To update SAT on Android you can do this via Termux. Open terminal and run:
```
$ pkg install git
$ /data/local/sat/sat -update
```


   [releases]: <https://github.com/SoulHunter24/android-tool/releases>
   [here]: <https://github.com/SoulHunter24/android-tool/blob/master/documentation.md>
   [Termux]: <https://termux.com/>
   
