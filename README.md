# About the project

SAT is a script created for unpack/repack image files (especially Generic System Images).It is available on Linux and Android devices. The main aim of SAT is to make some steps simple and automatically. It also contains some features related to GSIs:

- reduce size of system image file
- convert system from AB architecture to A-only

**Features for unpack/repack**
* possible to provide custom names/directories for RAW_IMG, F_SPARSE_IMG, M_DIR
* SPARSE_IMG is a base name for RAW_IMG and F_SPARSE_IMG
* finding alternative names/dirs if busy (RAW_IMG and F_SPARSE_IMG)
* can create new mount point directories if default/provided M_DIR is busy
* each mounted RAW_IMGs informations are stored, so no need to specify M_DIRs
* prompt warning before overwriting files
* script checks sense of used options eg. -a with -u
* unmount and remove all M_DIRs created by program and stored informations about it (-c option)
* colored UI
* print list of mounted RAW_IMGs with corresponding M_DIRs (-ml option)
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
The script will detect your system OS and architecture automatically.

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

**(2) TWRP**\
Just download **[this]** file and flash it in TWRP.

# Usage
SAT has basiclly 4 modes (auto, unpack, repack, no-mode). In each mode you can use some addiotional options (possible to use few options in one command). To use SAT you must run it in terminal with root access (needed to mount files):
```
$ su
# ./sat.sh <OPTIONS>
```
**See a full documentation [here]**

# Update
To update SAT run below command:
```
$ ./sat.sh -update
```
It will do everything automatically and keeps your settings in "default.conf" file.


   [releases]: <https://github.com/SoulHunter24/android-tool/releases>
   [here]: <https://github.com/SoulHunter24/android-tool/blob/master/documentation.md>
   [this]: <https://github.com/SoulHunter24/android-tool/releases>
   [Termux]: <https://termux.com/>
   
