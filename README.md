# About the project

SAT is a script created for unpack/repack image files (especially Generic System Images). The aim of SAT is to make some steps simple and automatically. It also contains some features related to GSIs:

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

In order to use SAT, you have to install some additional packages:
- simg2img
- img2simg

**On Ubuntu:**
```
$ sudo apt-get install simg2img img2simg
```

# Installation
To install SAT just clone this repo:
```
$ git clone https://github.com/SoulHunter24/android-tool.git
```
**or**\
<br>
download and unpack archive from **[releases]**

# Usage
SAT has basiclly 4 modes (auto, unpack, repack, no-mode). In each mode you can use some addiotional options (possible to use few options in one command). To use SAT you must run it with root access (needed to mount files):
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
   
