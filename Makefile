NAME := gtrr

prefix ?= /usr/local
exec_prefix ?= $(prefix)
bindir ?= $(exec_prefix)/bin

.PHONY: all link install uninstall

all:
	@echo 'Type `make install` to install $(NAME) system-wide'

link:
	ln -sf $${PWD}/bin/$(NAME).sh $(bindir)/$(NAME)

install:
	install bin/$(NAME).sh $(bindir)/$(NAME)

uninstall:
	rm $(bindir)/$(NAME)
