.POSIX:
	OS = $(shell uname -s)
	ifndef PREFIX
		PREFIX = /usr/local
	endif
	ifndef MANPREFIX
		MANPREFIX = $(PREFIX)/share/man
	endif

install:
	INSTALL_PATH = $(PREFIX)/bin/music-dl
	cp -f music-dl.sh $(INSTALL_PATH)
	chmod 755 $(INSTALL_PATH)
	if [ "$(OS)"!="Linux" ]; then \
		mkdir -p $(HOME)/.music-dl/cache; \
		mkdir $(HOME)/.music-dl/config; \
	fi \
	else \
		mkdir $(HOME)/.config/music-dl; \
		mkdir $(HOME)/.cache/music-dl; \
	fi \

uninstall:
	rm -f $(INSTALL_PATH)
	if [ "$(OS)"!="Linux" ]; then \
		rm -fdr $(HOME)/.music-dl/cache; \
		rm -fdr $(HOME)/.music-dl/config; \
	fi \
	else \
		rm -fdr $(HOME)/.config/music-dl; \
		rm -fdr $(HOME)/.cache/music-dl; \
	fi \

.PHONY: install uninstall
