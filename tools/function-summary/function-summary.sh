#/usr/bin/env bash
#
# This script generates lists of functions generated by bindgen, on one side,
# and static inline functions in notcurses.h on the other, grouped by prefix.
# It also generates some statistics.
#
# It would be nice if this script could check for changes in the body of
# filtered functions, by asking git... between the date of today and a custom
# past date you want to check out (modified file in the bindings).
#
# I should probably re-do this in Rust, and put it as an advanced example…


# TODO:enhancement: support multiple paths
PATH_SOURCE_FILE="../../include/notcurses/notcurses.h"

# this is the path to the latest bindgen generated rust sources
# TODO: retrieve it automatically, from the target folder, the most recently created/updated)
PATH_BINDGEN_LATEST="bindgen_20210406.rs"

# these are the main function prefixes used in notcurses (before the first `_`) for STATS_FILE
# NOTE: updated manually
PREFIX_LIST="cell channel ncblit ncdirect ncdplot ncfadectx ncfdplane nckey ncmenu ncmetric ncmultiselector ncpile ncpixel  ncplane ncprogbar ncreader ncreel ncselector ncsubproc nctab nctree ncuplot ncvisual notcurses palette"


OUTPUT_DIR="out-$(date +%Y%m%d)"
OUTPUT_DIR_BG="$OUTPUT_DIR/bindgen" # (bindgen generated)
OUTPUT_DIR_SI="$OUTPUT_DIR/static" # (static inline)
STATS_FILE="$OUTPUT_DIR/STATS"

TERM="static inline"

GREP="/bin/grep"
CUT="/usr/bin/cut"
SED="/bin/sed"
WC="/usr/bin/wc"
UNIQ="/usr/bin/uniq"
REV="/usr/bin/rev"
SORT="/usr/bin/sort"

# show the list of functions that are static inline
listfn() {
	"$GREP" "$TERM" "$PATH_SOURCE_FILE" -A 1 | $GREP -v -- "--" | $SED /^static.*/d | $CUT -d '(' -f1
}
listfn_bindgen() {
	"$GREP" "pub fn" "$PATH_BINDGEN_LATEST" | $CUT -d'(' -f1 | $REV | $CUT -d' ' -f1 | $REV
}

# show the number of different prefixes there are
listprefixes() {
	listfn | $CUT -d'_' -f1 | $SORT | $UNIQ
}
listprefixes_bindgen() {
	listfn_bindgen | $CUT -d'_' -f1 | $GREP -v '^$' | $SORT | $UNIQ
}


generate() {

	mkdir -p "$OUTPUT_DIR_BG"
	mkdir -p "$OUTPUT_DIR_SI"

	echo "GENERAL" | tee $STATS_FILE
	echo "-------"| tee -a $STATS_FILE
	echo -n "bindgen generated functions (bg): " | tee -a $STATS_FILE
	listfn_bindgen | $WC -l | tee -a $STATS_FILE
	echo -n "static inline functions (si): " | tee -a $STATS_FILE
	listfn | $WC -l | tee -a $STATS_FILE
	echo | tee -a $STATS_FILE


	echo "grouped by the following prefixes:" | tee -a $STATS_FILE
	echo $PREFIX_LIST | tee -a $STATS_FILE
	echo "--------------------------" | tee -a $STATS_FILE
	echo -e "            (bg, si)\n" | tee -a $STATS_FILE

	for prefix in $PREFIX_LIST; do
		printf "%.12s" "$prefix:        " | tee -a $STATS_FILE
		echo -en "(" | tee -a $STATS_FILE
		listfn_bindgen | $GREP "^$prefix" | $UNIQ -u | $WC -l | tr -d '\n' | tee -a $STATS_FILE
		echo -en ", " | tee -a $STATS_FILE
		listfn | $GREP "^$prefix" | $UNIQ -u | $WC -l | tr -d '\n' | tee -a $STATS_FILE
		echo ")" | tee -a $STATS_FILE

		# create the files
		listfn_bindgen | $GREP "^$prefix" | $UNIQ -u | $SORT > "$OUTPUT_DIR_BG/$prefix" | tee -a $STATS_FILE
		listfn | $GREP "^$prefix" | $UNIQ -u | $SORT > "$OUTPUT_DIR_SI/$prefix" | tee -a $STATS_FILE

		filterout="$filterout^$prefix|"
	done

	# DEBUG: show filtered out
	filterout="${filterout::-1}"
	#echo -e "$filterout" # DEBUG

	# show/save the rest not prefixed
	echo -en "\nrest of the functions (bg/si):" | tee -a $STATS_FILE
	echo -en "(" | tee -a $STATS_FILE
	listfn | $GREP -vE "$filterout" | $WC -l | tr -d '\n' | tee -a $STATS_FILE
	echo -en ", " | tee -a $STATS_FILE
	listfn_bindgen | $GREP -vE "$filterout" | $WC -l | tr -d '\n' | tee -a $STATS_FILE
	echo ")" | tee -a $STATS_FILE

	listfn_bindgen | $GREP -vE "$filterout" | $UNIQ -u | $SORT > "$OUTPUT_DIR_BG/_NON_FILTERED" | tee -a $STATS_FILE
	listfn | $GREP -vE "$filterout" | $UNIQ -u | $SORT > "$OUTPUT_DIR_SI/_NON_FILTERED" | tee -a $STATS_FILE

	echo -e "\n» results generated in folder \"$OUTPUT_DIR\""

} #/generate

main() {

	if [[ $1 == "p" ]]; then
		listprefixes
	elif [[ $1 == "f" ]]; then
		listfn
	elif [[ $1 == "pbind" ]]; then
		listprefixes_bindgen
	elif [[ $1 == "fbind" ]]; then
		listfn_bindgen
	elif [[ $1 == "generate" ]]; then
		generate
	else
		echo -e "I need an argument:"
		echo -e "\tp       list static inline uniq fn prefixes"
		echo -e "\tf       list static inline functions"
		echo
		echo -e "\tpbind   list bindgen generated uniq fn prefixes"
		echo -e "\tfbind   list bindgen generated functions"
		echo
		echo -e "\tgenerate"
		echo -e "          create an output subfolder with today's date and save in there"
		echo -e "          a series of textfiles named by prefix, with the list of functions:"
		echo -e "          1) generated by bindgen, and 2) static inline ones in notcurses.h"
		echo
	fi
}

main $1
