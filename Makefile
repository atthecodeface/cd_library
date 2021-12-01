LIBRARY_ROOT = $(PWD)

help:
	@echo "Add help here ${LIBRARY_ROOT}"
	@echo ""
	@echo "To update the source.hashdeep hash file based on updated flac files"
	@echo "  make update_source_hashes"
	@echo ""
	@echo "To verify the source flac files are not corrupted and match the hashes in the latest update_hashes"
	@echo "  make verify_source"
	@echo ""
	@echo "The target 'rsync_to_backup_mnt3' attempts to sync *everything* in the library to /mnt3 in archive mode"
	@echo "The target 'rsync_to_mnt' attempts to sync the mp3 to a FAT32 file system in /mnt"

.PHONY: check_in_library_root
check_in_library_root:
	@test -f ${LIBRARY_ROOT}/library.json || (echo "Bad root of library ${LIBRARY_ROOT}" ; false)

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
	cd ${LIBRARY_ROOT}
	find source -name '*.flac' | xargs hashdeep -k source.hashdeep -eX

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
	cd ${LIBRARY_ROOT}
	find mp3 -name '*.mp3' | xargs hashdeep -k mp3.hashdeep -eX

rsync_to_mnt: check_in_library_root
	(cd ${LIBRARY_ROOT} && rsync -vrltD mp3 /mnt)

rsync_to_mnt2: check_in_library_root
	(cd ${LIBRARY_ROOT} && rsync -vrltD mp3 /mnt2)

rsync_to_backup_mnt3: check_in_library_root
	(cd ${LIBRARY_ROOT} && rsync -av ./ /mnt3)

rsync_to_nas: check_in_library_root
	(cd ${LIBRARY_ROOT} && rsync -av . writer@10.1.17.34:/nas/audio/turnipdb_library)
