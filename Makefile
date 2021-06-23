OS = ${shell uname -s}
ifndef PREFIX
	PREFIX = /usr/local
endif
ifndef MANPREFIX
	MANPREFIX = ${PREFIX}/share/man
endif
INSTALL_PATH = ${PREFIX}/bin/music-dl

install:
	cp -f music-dl.sh ${INSTALL_PATH}
	chmod 755 ${INSTALL_PATH}

clean:
	rm -f ${INSTALL_PATH}

uninstall:
	rm -f ${INSTALL_PATH}

.PHONY: install clean uninstall
