#!/bin/bash
# COLOURS
NC='\033[0m' # no colour
GREEN='\033[0;32m' # green
ORANGE='\033[0;33m' # orange
BLUE='\033[0;34m' # blue
CYAN='\e[0;36m' # cyan
function corange {
	local STRING=${1}
	printf "${ORANGE}${STRING}${NC}"
}
function cgreen {
	local STRING=${1}
	printf "${GREEN}${STRING}${NC}"
}
function ccyan {
	local STRING=${1}
	printf "${CYAN}${STRING}${NC}"
}

FILE=$1
JSON=$2
RUN=$3
if [[ -n "${FILE}" && -n "${JSON}" ]]; then
	## set vcsa directory name
	BASEDIR="${PWD}"
	VCSADIR="${PWD}/vcsa"
	echo "ISO: "$FILE

	# check for old directories and remove
	regex="vcsa"
	for DIR in ${BASEDIR}/*; do
		if [[ -d "$DIR" && ! -L "$DIR" ]]; then
			if [[ $DIR =~ $REGEX ]]; then
				echo "UMOUNT & DELETE: "$DIR
				umount $DIR
				#rm -rf $DIR
			fi
		fi
	done

	# create and mount new directory
	echo "CREATE & MOUNT: "$VCSADIR $FILE
	mkdir -p $VCSADIR
	mount -t iso9660 -o loop,ro $FILE $VCSADIR

	if [[ "${RUN}" == "true" ]]; then
		$VCSADIR/vcsa-cli-installer/lin64/vcsa-deploy install -v --no-ssl-certificate-verification ${JSON} --accept-eula
	else
		$VCSADIR/vcsa-cli-installer/lin64/vcsa-deploy install -v --no-ssl-certificate-verification ${JSON} --accept-eula --precheck-only
	fi
	#umount $vcsadir
else
	printf "[$(corange "ERROR")]: Usage: $(cgreen "vcenter.create") $(ccyan "<vcsa.iso> <vcsa.json> [ <true> ]")\n" 1>&2
fi
