NAME := gtrr

prefix ?= /usr/local
exec_prefix ?= $(prefix)
bindir ?= $(exec_prefix)/bin

.PHONY: all install

all:
	@echo 'Type `make install` to install $(NAME) system-wide'

install:
	install bin/$(NAME).sh $(bindir)/$(NAME)

uninstall:
	rm $(bindir)/$(NAME)

