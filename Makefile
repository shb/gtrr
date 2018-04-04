NAME := gtrr

prefix ?= /usr/local
exec_prefix ?= $(prefix)
bindir ?= $(exec_prefix)/bin

gtrr_run_NAME=gtrun

.PHONY: all link install uninstall

all:
	@echo 'Type `make install` to install $(NAME) system-wide'

link:
	ln -sf $${PWD}/bin/$(gtrr_run_NAME).sh $(bindir)/$(gtrr_run_NAME)

install:
	install bin/$(gtrr_run_NAME).sh $(bindir)/$(gtrr_run_NAME)

uninstall:
	rm $(bindir)/$(gtrr_run_NAME)
