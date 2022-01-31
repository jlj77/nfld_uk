#!/bin/bash

function clean_up {
	rm -f /var/tmp/bookclub_master_tidy.html
	rm -f /var/tmp/bookclub_master_parsed.html
	rm -f /var/tmp/all_urls
	rm -f /var/tmp/pad_urls
	rm -f /var/tmp/pad_filenames
	if [[ -f /var/tmp/pre_sakura ]]; then
		rm -f /var/tmp/pre_sakura
	fi
	rm -f /var/tmp/add_sakura
}

# Do our best to remove our temp files regardless
trap "clean_up" EXIT SIGQUIT SIGTERM

# Create the lines needed to add Sakura to all of the HTML we generate
echo "<link rel=stylesheet href='./sakura/css/normalize.css' type='text/css'>" > /var/tmp/add_sakura
echo "<link rel=stylesheet href='./sakura/css/sakura-vader.css' type='text/css'>" >> /var/tmp/add_sakura

# Get HTML export of the latest 'root' Etherpad for the book club; then
# 	Save an HTML Tidy'd version for later; and
# 	Substitute all the Etherpad related URLs such that
#			pad.nfld.uk/p/padX becomes nfld.uk/padX
curl https://pad.nfld.uk/p/bookclub_master/export/html | \
	tidy | tee /var/tmp/bookclub_master_tidy.html | \
	sed -e 's/pad\.nfld\.uk\/p/nfld\.uk/' > /var/tmp/bookclub_master_parsed.html

# Dump all URLs in the 'tidied' root document
lynx -dump -listonly /var/tmp/bookclub_master_tidy.html > /var/tmp/all_urls

# Extract just the Etherpad related URLs
awk 'match($0, /\/pad/) { print $2 }' /var/tmp/all_urls > /var/tmp/pad_urls

# Map them as an array of Etherpads
mapfile -t PADS < /var/tmp/pad_urls

# Extract the names of the Etherpads; and
#		Add HTML file extensions to those names
gawk 'match($0, /\/nfld.uk\/([a-zA-Z0-9_]*)/, i) { print i[1]".html" }' /var/tmp/bookclub_master_parsed.html | \
	uniq > /var/tmp/pad_filenames

# Map those new names as an array of destination filenames
mapfile -t FILENAMES < /var/tmp/pad_filenames

# For each Etherpad in the array of Etherpads:
#		Copy the corresponding HTML file to a unique .old file; and
#		Replace that HTML file with the latest, 'tidied' HTML export of said Etherpad
for i in "${!PADS[@]}"; do
	PAD_EXPORT="${PADS[i]}/export/html"
	ARCHIVE_NAME="${FILENAMES[i]}.old"
	if [[ -f "${FILENAMES[i]}" ]]; then
		cp "${FILENAMES[i]}" "${ARCHIVE_NAME}"
	fi
	curl "${PAD_EXPORT}" | tidy > /var/tmp/pre_sakura

	# Insert Sakura in the header
	sed '/<head>/r /var/tmp/add_sakura' /var/tmp/pre_sakura > "${FILENAMES[i]}"
done

# Do the same for the HTML export of the 'root' Etherpad
cp bookclub_master.html bookclub_master.html.old

# Do the same substituting of Etherpad names for names with HTML file extensions for the 'root' Etherpad
awk '{gsub(/\/nfld.uk\/[a-zA-Z0-9_]*/, "&.html")}1' /var/tmp/bookclub_master_parsed.html > ./bookclub_master.html
