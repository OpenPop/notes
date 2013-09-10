# Generic makefile for DVCS conversions using reposurgeon
#
# Steps to using this:
# 0. Copy this into a scratch directory as Makefile
# 1. Make sure git, svn, rsync, reposurgeon and repopuller are on your $PATH.
# 2. Set PROJECT to the name of your project
# 3. Set SOURCE_VCS to svn or cvs
# 4. Set TARGET_VCS to git, hg, or bzr
# 5. For svn, set SVN_URL to point at the remote repository you want to convert.
# 6. For cvs, set CVS_HOST to the repository hostname
# 7. Create a $(PROJECT).lift script for your custom commands, initially empty.
# 8. Create a $(PROJECT).authormap file mapping local usernames to DVCS IDs.
# 9. (Optional) Set EXTRAS to name extra metadata such as a comments mailbox.
# 10. Invoke make on this file.

PROJECT = openpopulous
SOURCE_VCS = svn
TARGET_VCS = git
EXTRAS = 
SVN_URL = svn://svn.code.sf.net/p/openpopulous/code
CVS_HOST = $(PROJECT).cvs.sourceforge.net
VERBOSITY = "verbose 1"

# Configuration ends here

.PHONY: local-clobber remote-clobber gitk gc compare clean dist

default: $(PROJECT)-$(TARGET_VCS)

# Build the repo from the fast-import stream
$(PROJECT)-$(TARGET_VCS): $(PROJECT).fi
	rm -fr $(PROJECT)-$(TARGET_VCS); reposurgeon "read $(PROJECT).fi" "prefer $(TARGET_VCS)" "rebuild $(PROJECT)-$(TARGET_VCS)"

ifeq ($(SOURCE_VCS),svn)

# Build the fast-import stream from the Subversion stream dump
$(PROJECT).fi: $(PROJECT).svn $(PROJECT).lift $(PROJECT).authormap $(EXTRAS)
	reposurgeon $(VERBOSITY) "set svn_nobranch" "read $(PROJECT).svn" "prefer git" "script $(PROJECT).lift" "fossils write >$(PROJECT).fo" "write $(PROJECT).fi"

# Build the Subversion stream dump from the local mirror
$(PROJECT).svn: $(PROJECT)-mirror
	repopuller $(PROJECT)-mirror
	svnadmin dump $(PROJECT)-mirror/ >$(PROJECT).svn

# Build a local mirror of the remote Subversion repo
$(PROJECT)-mirror:
	repopuller $(SVN_URL)

# Force rebuild of the fast-import stream from the local mirror on the next make
local-clobber: clean
	rm -fr $(PROJECT).fi $(PROJECT)-$(TARGET_VCS) *~ .rs* $(PROJECT)-conversion.tar.gz 

# Force full rebuild from the remote repo on the next make.
remote-clobber: local-clobber
	rm -fr $(PROJECT).svn $(PROJECT)-mirror $(PROJECT)-checkout

# Make a local checkout of the Subversion mirror for inspection
$(PROJECT)-checkout: $(PROJECT)-mirror
	svn co file://${PWD}/$(PROJECT)-mirror $(PROJECT)-checkout

# Get the Subversion state of the author mapping
$(PROJECT).map: $(PROJECT).svn
	reposurgeon "read $(PROJECT).svn" "authors write $(PROJECT).map"

endif

ifeq ($(SOURCE_VCS),cvs)

#
# The following productions are CVS-specific
#

# Mirror a CVS repo (from a site with a SourceForge-like CVS layout).
# You may need to modify this.
$(PROJECT)-checkout:
	cvs -q "-d:ext:$(CVS_HOST)/$(PROJECT)" co $(PROJECT) $(PROJECT)-checkout

# Build the fast-import stream from the repository
$(PROJECT).fi: $(PROJECT).lift $(PROJECT).authormap $(EXTRAS)
	reposurgeon $(VERBOSITY) "set svn_nobranch" "read $(PROJECT)-checkout" "prefer git" "script $(PROJECT).lift" "fossils write >$(PROJECT).fo" "write $(PROJECT).fi"

endif

ifeq ($(TARGET_VCS),git)

#
# The following productions are git-specific
#

# Browse the generated git repository
gitk: $(PROJECT)-git
	cd $(PROJECT)-git; gitk --all

# Run a garbage-collect on the generated git repository.  Import doesn't.
# This repack call is the active part of gc --aggressive.  This call is
# tuned for very large repositories.
gc: $(PROJECT)-git
	cd $(PROJECT)-git; time git -c pack.threads=1 repack -AdF --window=1250 --depth=250

# Make a conversion using a competing tool
$(PROJECT)-git-svn:
	git svn --stdlayout --no-metadata --authors-file=$(PROJECT).authormap clone file://${PWD}/$(PROJECT)-mirror $(PROJECT)-git-svn

# Compare file manifests on the master branch
compare: $(PROJECT)-git-svn $(PROJECT)-git
	@echo; echo "Comparing the directory manifests..."
	@rm -f GITSVN.MANIFEST PROJECTGIT.MANIFEST
	@(cd $(PROJECT)-git-svn >/dev/null; find . -type f | sort | fgrep -v '.git') >GITSVN.MANIFEST
	@(cd $(PROJECT)-git >/dev/null; find . -type f | sort | fgrep -v '.git') >PROJECTGIT.MANIFEST
	@echo "Comparing file manifests..."
	@diff -u GITSVN.MANIFEST PROJECTGIT.MANIFEST
	@echo "No diff output is good news"
	@echo; echo "Comparing file contents..."
	@set -e; for file in `cd $(PROJECT)-git-svn >/dev/null; git ls-files`; do cmp $(PROJECT)-git-svn/$$file $(PROJECT)-git/$$file; done
	@echo "No cmp output is good news"

# Compare all files in all revisions.  Ignore .gitignores, as reposurgeon
# makes them  but git-svn does not.
repodiffer: $(PROJECT)-git-svn $(PROJECT)-git
	repodiffer --ignore="gitignore,comment" --fossil-map=$(PROJECT).fo $(PROJECT)-git $(PROJECT)-git-svn | tee REPODIFFER.LOG

endif

# General cleanup and utility
clean:
	rm -fr *~ .rs* $(PROJECT)-conversion.tar.gz REPODIFFER.LOG

# Bundle up the conversion metadata for shipping
SOURCES = Makefile $(PROJECT).lift $(PROJECT).map $(EXTRAS)
$(PROJECT)-conversion.tar.gz: $(SOURCES)
	tar --dereference --transform 's:^:$(PROJECT)-conversion/:' -czvf $(PROJECT)-conversion.tar.gz $(SOURCES)

dist: $(PROJECT)-conversion.tar.gz

