#!/bin/sh
#  merge_config.sh - Takes a list of config fragment values, and merges
#  them one by one. Provides warnings on overridden values, and specified
#  values that did not make it to the resulting .config file (due to missed
#  dependencies or config symbol removal).
#
#  Portions reused from kconf_check and generate_cfg:
#  http://git.yoctoproject.org/cgit/cgit.cgi/yocto-kernel-tools/tree/tools/kconf_check
#  http://git.yoctoproject.org/cgit/cgit.cgi/yocto-kernel-tools/tree/tools/generate_cfg
#
#  Copyright (c) 2009-2010 Wind River Systems, Inc.
#  Copyright 2011 Linaro
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License version 2 as
#  published by the Free Software Foundation.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#  See the GNU General Public License for more details.

clean_up() {
	rm -f $TMP_FILE
	exit
}
trap clean_up HUP INT TERM

usage() {
	echo "Usage: $0 [OPTIONS] [CONFIG [...]]"
	echo "  -h    display this help text"
	echo "  -m    only merge the fragments, do not execute the make command"
	echo "  -n    use allnoconfig instead of alldefconfig"
	echo "  -r    list redundant entries when merging fragments"
	echo "  -O    dir to put generated output files.  Consider setting \$KCONFIG_CONFIG instead."
}

RUNMAKE=true
ALLTARGET=alldefconfig
WARNREDUN=false
OUTPUT=.

while true; do
	case $1 in
	"-n")
		ALLTARGET=allnoconfig
		shift
		continue
		;;
	"-m")
		RUNMAKE=false
		shift
		continue
		;;
	"-h")
		usage
		exit
		;;
	"-r")
		WARNREDUN=true
		shift
		continue
		;;
	"-O")
		if [ -d $2 ];then
			OUTPUT=$(echo $2 | sed 's/\/*$//')
		else
			echo "output directory $2 does not exist" 1>&2
			exit 1
		fi
		shift 2
		continue
		;;
	*)
		break
		;;
	esac
done

if [ "$#" -lt 1 ] ; then
	usage
	exit
fi


INITFILE=$1

MERGE_FILE=$2
SED_CONFIG_EXP="s/^\(# \)\{0,1\}\(CONFIG_[a-zA-Z0-9_]*\)[= ].*/\2/p"
TMP_FILE=~/tmp.config
TMP_FILE1=~/tmp1.config

echo "Using $INITFILE as base"
echo "Merging $MERGE_FILE"
sed -n "$SED_CONFIG_EXP" $INITFILE > $TMP_FILE1
sed -n "$SED_CONFIG_EXP" $MERGE_FILE >> $TMP_FILE1
#grep CONFIG $INITFILE  > $TMP_FILE1
#grep CONFIG $MERGE_FILE >> $TMP_FILE1
cat $TMP_FILE1 | sort | uniq > $TMP_FILE

private=~/private62
common=~/common62
echo > $private
echo > $common
t1=~/t62
echo > $t1


# Merge files, printing warnings on overridden values
echo  "Merging $MERGE_FILE" >> $private
echo  "Merging $MERGE_FILE" >> $common
#CFG_LIST=`cat $TMP_FILE`
cp $MERGE_FILE $private
CFG_LIST=$(sed -n "$SED_CONFIG_EXP" $MERGE_FILE)
for CFG in $CFG_LIST ; do
	#grep -q -w $CFG $MERGE_FILE || continue
	echo $CFG > $t1
	PREV_VAL=$(grep -w $CFG $INITFILE)
	NEW_VAL=$(grep -w $CFG $MERGE_FILE)
	if [ "x$PREV_VAL" = "x$NEW_VAL" ] ; then
		echo $NEW_VAL >> $common
		sed -i "/$CFG[ =]/d" $private
	fi
done
