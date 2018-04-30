#!/bin/sh
# Copyright (c)2013 Devin Teske. All rights reserved.
increment=1   # How much to increment % each time (must be even divisor of 100)
sleep_sec=3   # Time to sleep in-between increments
pbar_size=17  # How big is the mini-progressbar?
txt_size=28   # Maximum width for labels (file names)
files="base.txz dict.txz doc.txz games.txz ports.txz src.txz" # Files to fake-fetch
### Rest below shouldn't need editing ###
spin="/-\|"
pct_lsize=$(( ( $pbar_size - 4 ) / 2 ))
pct_rsize=$pct_lsize
[ $(( $pct_lsize * 2 + 4 )) -ne $pbar_size ] &&
	pct_rsize=$(( $pct_rsize + 1 ))
dun_lsize=$pct_lsize dun_rsize=$pct_rsize
pen_lsize=$(( ( $pbar_size - 7 ) / 2 ))
pen_rsize=$pen_lsize
[ $(( $pen_lsize * 2 + 7 )) -ne $pbar_size ] &&
	pen_rsize=$(( $pen_rsize + 1 ))
n=1
nfiles=$( set -- $files; echo $# )
for file in $files; do # Loop through each file, ...
	pct=
	while [ ${pct:-0} -lt 100 ]; do # ... incrementing 1% each sub-loop
		[ "$sleep_sec" ] && sleep $sleep_sec
		pct=$(( ${pct:--$increment} + $increment ))
		#
		# Create the progress bar
		#
		pbar=$( printf "%${pct_lsize}s%3u%%%${pct_rsize}s" \
		               "" $pct "" )
		# Calculate the width thereof
		width=$(( $pct * $pbar_size / 100 ))
		# Round up based on one-tenth of a percent
		[ $(( $pct * $pbar_size % 100 )) -gt 50 ] &&
			width=$(( $width + 1 ))
		#
		# Make a copy of the pbar and split the copy into two halves
		# (we'll insert the ANSI delimiter in between)
		#
		lpbar="$pbar" rpbar="$pbar" rwidth=$(( $pbar_size - $width ))
		while [ ${#lpbar} -gt $width ]; do lpbar="${lpbar%?}"; done
		while [ ${#rpbar} -gt $rwidth ]; do rpbar="${rpbar#?}"; done
		#
		# Finalize the progress bar
		#
		pbar="\Zb\Zr\Z4$lpbar\ZR$rpbar\Zn"
		#
		# Build the prompt text
		#
		p=1 prompt=
		for f in $files; do
			flabel="$f"
			while [ ${#flabel} -gt $txt_size ]; do
				flabel="${flabel%?}"
			done
			if [ ${#flabel} -ne ${#f} ]; then
				while [ ${#flabel} -gt $(( $txt_size - 3 )) ]
				do flabel="${flabel%?}"; done
				flabel="$flabel..."
			fi
			if [ $n -eq $p -a $pct -ne 100 ]; then
				# This is the file we're processing right now
				while [ ${#flabel} -gt $(( $txt_size - 3 )) ]
				do flabel="${flabel%?}"; done
				spin_char=$( echo "$spin" | sed -e \
				 "s/.\{0,$(( $pct % ${#spin} ))\}\(.\).*/\1/" )
				prompt="$prompt$(
					printf "\\\Zb%-${txt_size}s\\\ZB %c " \
					       "${flabel%...}..." "$spin_char"
				)"
			else
				prompt="$prompt$(
					printf "%-${txt_size}s %c " \
					       "$flabel" " "
				)"
			fi
			if [ $p -eq $n -a $pct -ne 100 ]; then
				prompt="$prompt [$pbar]\n"
			elif [ $p -gt $n ]; then
				prompt="$prompt [$(
					printf "%${pen_lsize}s" ""
				)Pending$(
					printf "%${pen_rsize}s" ""
				)]\n"
			else
				prompt="$prompt [\Zb\Zr\Z2$(
					printf "%${dun_lsize}s" ""
				)Done$(
					printf "%${dun_rsize}s" ""
				)\Zn]\n"
			fi
			p=$(( $p + 1 ))
		done
		#
		# Add trailing information
		#
		prompt="$prompt\nFetching distribution files...\n"
		prompt="$prompt\n  \ZbOverall Progress:\Zn"
		#
		# Calculate total overall progress
		#
		opct=$(( ( 100 * $n - 100 + $pct ) / $nfiles ))
		# Round up based on one-tenth of a percent
		[ $(( (100*$n - 100 + $pct) * 10 / $nfiles % 100 )) -gt 50 ] &&
			opct=$(( $opct + 1 ))

		printf "XXX\n%s\nXXX\n%u\n" "$prompt" $opct
	done
	n=$(( $n + 1 ))
done | dialog --title 'Fetching Distribution' \
	--backtitle 'FreeBSD Installer' --colors \
	--gauge "$prompt" 14 $(( $txt_size + $pbar_size + 10 ))
