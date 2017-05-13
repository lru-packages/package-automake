NAME=automake
VERSION=1.15
ITERATION=1.lru
PREFIX=/usr/local
LICENSE=GPLv2
VENDOR="Automake contributors"
MAINTAINER="Ryan Parman"
DESCRIPTION="Automake is a tool for automatically generating Makefile.in files compliant with the GNU Coding Standards."
URL=https://www.gnu.org/software/automake/
ACTUALOS=$(shell osqueryi "select * from os_version;" --json | jq -r ".[].name")
EL=$(shell if [[ "$(ACTUALOS)" == "Amazon Linux AMI" ]]; then echo alami; else echo el; fi)
RHEL=$(shell [[ -f /etc/centos-release ]] && rpm -q --queryformat '%{VERSION}' centos-release)

#-------------------------------------------------------------------------------

all: info clean compile install-tmp package move

#-------------------------------------------------------------------------------

.PHONY: info
info:
	@ echo "NAME:        $(NAME)"
	@ echo "VERSION:     $(VERSION)"
	@ echo "ITERATION:   $(ITERATION)"
	@ echo "PREFIX:      $(PREFIX)"
	@ echo "LICENSE:     $(LICENSE)"
	@ echo "VENDOR:      $(VENDOR)"
	@ echo "MAINTAINER:  $(MAINTAINER)"
	@ echo "DESCRIPTION: $(DESCRIPTION)"
	@ echo "URL:         $(URL)"
	@ echo "OS:          $(ACTUALOS)"
	@ echo "EL:          $(EL)"
	@ echo "RHEL:        $(RHEL)"
	@ echo " "

#-------------------------------------------------------------------------------

.PHONY: clean
clean:
	rm -Rf /tmp/installdir* automake*

#-------------------------------------------------------------------------------

.PHONY: compile
compile:
	wget https://ftp.gnu.org/gnu/$(NAME)/$(NAME)-$(VERSION).tar.xz
	tar xf $(NAME)-$(VERSION).tar.xz
	cd ./$(NAME)-$(VERSION) && \
		./configure --prefix=$(PREFIX) && \
		make

#-------------------------------------------------------------------------------

.PHONY: install-tmp
install-tmp:
	mkdir -p /tmp/installdir-$(NAME)-$(VERSION);
	cd ./$(NAME)-$(VERSION) && \
		make install DESTDIR=/tmp/installdir-$(NAME)-$(VERSION);
	mv -f /tmp/installdir-$(NAME)-$(VERSION)/usr/local/share/info/dir /tmp/installdir-$(NAME)-$(VERSION)/usr/local/share/info/dir-$(NAME)-$(VERSION)

#-------------------------------------------------------------------------------

.PHONY: package
package:

	fpm \
		-s dir \
		-t rpm \
		-n $(NAME) \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--iteration $(ITERATION) \
		--license $(LICENSE) \
		--vendor $(VENDOR) \
		--prefix / \
		--url $(URL) \
		--description $(DESCRIPTION) \
		--rpm-defattrdir 0755 \
		--rpm-digest md5 \
		--rpm-compression gzip \
		--rpm-os linux \
		--rpm-dist $(EL)$(RHEL) \
		--rpm-auto-add-directories \
		usr/local/bin \
		usr/local/share \
	;

	#-------------------------------------------------------------------------------

.PHONY: move
move:
	mv *.rpm /vagrant/repo
