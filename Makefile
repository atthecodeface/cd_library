
LIBRARY_ROOT = $(PWD)

TURNIPRIPPERDB =/home/gavin/turnipripper/turnipripperdb

HASH_ME = SET_HASH_ME_TO_THE_WILDCARD_IN_SOURCE_TO_HASH_EXCLUDING_FLAC

CD_LIBRARY_MNT = /cd_library
CD_BACKUP_MNT = /cd_backup

SOURCE = ${CD_LIBRARY_MNT}/source
GENRE = GENRE=Specify_A_Genre
help:
	@echo "Add help here ${LIBRARY_ROOT}"
	@echo ""
	@echo "To update the source.hashdeep hash file based on updated flac files"
	@echo "  make update_source_hashes"
	@echo ""
	@echo "To verify the source flac files are not corrupted and match the hashes in the latest update_hashes"
	@echo "  make verify_source"
	@echo ""
	@echo "The target 'rsync_to_cd_library' attempts to sync mp3 and source in the library to /cd_library appropriately"
	@echo "The target 'rsync_to_mnt' attempts to sync the mp3 to a FAT32 file system in /mnt"
	@echo "The target 'rsync_to_mnt2' attempts to sync the mp3 to a FAT32 file system in /mnt2"
	@echo "The target 'rsync_to_nas' attempts to sync mp3 and source in the library to the NAS"
	@echo "The target 'export_to_sqlite' exports the JSON library into a sqlite file called lib.sql; that file cannot exist beforehand"
	@echo "The target 'import_from_sqlite' shows what an import into the JSON library from lib.sql would do, and provides a line to paste into bash to make it happen"
	@echo "The target 'encode_genre' provides a line to paste into bash to encode all the discs of a particular gener as mp3; '--max_discs 1000' or similar may be required after '--genre <GENRE>'"
	@echo ""

	@echo "To rip:"
	@echo "../turnipripperdb rip --device /dev/sr0 charlotte_bronte_jane_eyre_disc_16"

.PHONY: list
list:
	@LC_ALL=C $(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

.PHONY: check_in_library_root
check_in_library_root:
	@test -f ${LIBRARY_ROOT}/library.json || (echo "Bad root of library ${LIBRARY_ROOT}" ; false)

.ONESHELL:
update_source_hash: check_in_library_root
	cd ${LIBRARY_ROOT} 
	(find source -wholename ${HASH_ME}*.flac -fprint /dev/stderr -print0| xargs -0 hashdeep -c md5 -l ) > source.hashdeep.new
	touch source.hashdeep.new 
	cat source.hashdeep source.hashdeep.new > source.hashdeep.combined 
	sort --unique --field-separator=, --key=3d --key=2h --key=1g source.hashdeep.combined > source.hashdeep.updated 
	mv source.hashdeep source.hashdeep.bkp 
	mv source.hashdeep.updated source.hashdeep 

.ONESHELL:
update_source_hashes: check_in_library_root
	cd ${LIBRARY_ROOT} 
	(find source -name '*.flac' | xargs hashdeep -c md5 -l ) > source.hashdeep.new
	touch source.hashdeep.new 
	cat source.hashdeep source.hashdeep.new > source.hashdeep.combined 
	sort --unique --field-separator=, --key=3d --key=2h --key=1g source.hashdeep.combined > source.hashdeep.updated 
	mv source.hashdeep source.hashdeep.bkp 
	mv source.hashdeep.updated source.hashdeep 

.ONESHELL:
verify_source: check_in_library_root
	@echo "This will always exit with an error return code because of xargs and hashdeep interaction"
	@echo "It is clean if there are no errored files or reads below"
	cd ${LIBRARY_ROOT}/source
	find . -name *.flac | xargs hashdeep -k ../source.hashdeep -elX

.ONESHELL:
verify_hash: check_in_library_root
	@echo "This will always exit with an error return code because of xargs and hashdeep interaction"
	@echo "It is clean if there are no errored files or reads below"
	cd ${LIBRARY_ROOT}/source
	find ${HASH_ME} -name *.flac | xargs hashdeep -k ../source.hashdeep -elX

.ONESHELL:
update_mp3_hashes: check_in_library_root
	cd ${LIBRARY_ROOT} 
	(find mp3 -name '*.mp3' | xargs -n 100 -d '\n' hashdeep -c md5 -l ) > mp3.hashdeep.new
	touch mp3.hashdeep.new 
	cat mp3.hashdeep mp3.hashdeep.new > mp3.hashdeep.combined 
	sort --unique --field-separator=, --key=3d --key=2h --key=1g mp3.hashdeep.combined > mp3.hashdeep.updated 
	mv mp3.hashdeep mp3.hashdeep.bkp 
	mv mp3.hashdeep.updated mp3.hashdeep 

.ONESHELL:
verify_mp3: check_in_library_root
	@echo "This will always exit with an error return code because of xargs and hashdeep interaction"
	@echo "It is clean if there are no errored files or reads below"
	cd ${LIBRARY_ROOT}/mp3
	find . -name '*.mp3' | xargs hashdeep -k ../mp3.hashdeep -elX

.ONESHELL:
find_duplicate_hashes:
	@echo "This will print nothing if there are no files with 2 different hashes..."
	cd ${LIBRARY_ROOT}
	(awk 'match($$0, "[0-9]+,[0-9a-f]+,(.+flac)", m) {print m[1]}' source.hashdeep | uniq -c | sort -n | grep -v '    1 ' ) || true

rsync_to_mnt: check_in_library_root
	(cd ${LIBRARY_ROOT} && rsync -vrltD mp3 /mnt)

rsync_to_mnt2: check_in_library_root
	(cd ${LIBRARY_ROOT} && rsync -vrltD mp3 /mnt2)

try_to_cd_library: check_in_library_root
	(cd ${LIBRARY_ROOT} && rsync -anv ./mp3 ./source ${CD_LIBRARY_MNT})

rsync_to_cd_library: check_in_library_root
	(cd ${LIBRARY_ROOT} && rsync -av ./mp3 ./source ${CD_LIBRARY_MNT})

rsync_to_backup_mnt4:
	rsync -avn ./source ${CD_BACKUP_MNT}
	@echo "Now do: rsync -av ./source ${CD_BACKUP_MNT}"

rsync_to_nas: check_in_library_root
	(cd ${LIBRARY_ROOT} && rsync -av . writer@10.1.17.34:/nas/audio/turnipdb_library)

export_to_sqlite: check_in_library_root
	(cd ${LIBRARY_ROOT} && ${TURNIPRIPPERDB} database export --format sqlite3 --file lib.sql)

import_from_sqlite: check_in_library_root
	(cd ${LIBRARY_ROOT} && ${TURNIPRIPPERDB} --debug 9 database import --format sqlite3 lib.sql)
	@echo "Now run (cd ${LIBRARY_ROOT} && ${TURNIPRIPPERDB} --debug 9 database import --format sqlite3 --update lib.sql)"


# "audiobook",
# "choral",
# "christian",
# "dramatization",
# "language",
# "musical",
# "opera",
# "orchestral",
# "other",
# "pop",
# "vocal",
encode_genre: check_in_library_root
	@echo "${TURNIPRIPPERDB} disc --genre ${GENRE} --max_discs 1000 encode --output mp3/${GENRE} --source ${SOURCE}"

do_encode_genre: check_in_library_root
	${TURNIPRIPPERDB} disc --genre ${GENRE} --max_discs 1000 encode --output mp3/${GENRE} --source ${SOURCE}

encode_all: check_in_library_root
	${MAKE} GENRE=audiobook do_encode_genre
	${MAKE} GENRE=childrens do_encode_genre
	${MAKE} GENRE=choral do_encode_genre
	${MAKE} GENRE=christian do_encode_genre
	${MAKE} GENRE=dramatization do_encode_genre
	${MAKE} GENRE=jazz do_encode_genre
	${MAKE} GENRE=language do_encode_genre
	${MAKE} GENRE=musical do_encode_genre
	${MAKE} GENRE=opera do_encode_genre
	${MAKE} GENRE=orchestral do_encode_genre
	${MAKE} GENRE=other do_encode_genre
	${MAKE} GENRE=pop do_encode_genre
	${MAKE} GENRE=vocal do_encode_genre
