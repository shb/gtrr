#!/bin/sh

BEFORE_ALL=before.all
BEFORE_EACH=before.each
TESTS='*.test'
AFTER_ALL=after.all
AFTER_EACH=after.each

VERBOSE=0

_bailout () {
	echo "Bail out! $1"
	exit 1
}

_debug () {
	if [ "${VERBOSE}" != "0" ]; then
		echo "# $*"
	fi
}

run () {
	# Cache env vars for restoring them afterwards
	_BEFORE_ALL=$BEFORE_ALL
	_BEFORE_EACH=$BEFORE_EACH
	_TESTS=$TESTS
	_AFTER_ALL=$AFTER_ALL
	_AFTER_EACH=$AFTER_EACH

	for batch in $*; do
		if [ -d ${batch} ]; then
			_pdir=${PWD}
#			echo "# cd ${batch}"
			cd ${batch}

			if [ -r "${BEFORE_ALL}" ]; then
				_debug "source ${PWD}/${BEFORE_ALL}"
				if source "./${BEFORE_ALL}"; then true; else _bailout "Batch setup failed"; fi
			fi

			for TEST in $TESTS; do
				if [ -r "${TEST}" ]; then
					if [ -r "${BEFORE_EACH}" ]; then
#						echo "# source ${PWD}/${BEFORE_EACH}"
						if source "./${BEFORE_EACH}"; then true; else _bailout "Test setup failed"; fi
					fi
					OK=${_ntest}
#					echo "# source ${PWD}/${TEST}"
					source "./${TEST}"
					OK=$?
					let _ntest++
					if [ -r "${AFTER_EACH}" ]; then
						_debug "source ${PWD}/${AFTER_EACH}"
						if source "./${AFTER_EACH}"; then true; else _bailout "Test teardown failed"; fi
					fi
					if [ "${OK}" == "0" ]; then
						echo "ok ${_ntest} - ${TEST}"
					else
						echo "not ok ${_ntest} - ${TEST}"
					fi
				fi
			done

			if [ -r "${AFTER_ALL}" ]; then
				_debug "source ${PWD}/${AFTER_ALL}"
				if source "./${AFTER_ALL}"; then true; else _bailout "Batch teardown failed"; fi
			fi

#			echo "# ${_pdir}"
			cd "${_pdir}"
		fi
	done

	BEFORE_ALL=$_BEFORE_ALL
	BEFORE_EACH=$_BEFORE_EACH
	TESTS=$_TESTS
	AFTER_ALL=$_AFTER_ALL
	AFTER_EACH=$_AFTER_EACH
}

#
# Command: test
#
# Run a a suite of test batches
#
# Synopsis:
#
#     test [dir1] [dir2] ...
#
# Description:
# This shell script can run a suite of tests composed by several shell
# script, organized in a tree of directories. In each of the directories
# (current directory if none given):
#
# - If a file named "$BEFORE_ALL" is present it is executed first
# - If a file named "$BEFORE_EACH" is present it is executed before each test
# - Every file names `*.test` is executed in alphabetical order
# - If a file named "$AFTER_EACH" is present it is executed after each test
# - If a file named "$AFTER_ALL" is present it is executed last
#
# The files are sourced into `test` script so they have access to `test`
# internales and can modify its functioning.
#
# Dependency between test batches (in different directories) can be implemented
# by calling the `run` command inside the needed per- or post- requisite
# script.
#
# Setup of the whol test run can be pu inside a before-all script in the
# first or top-level test batch directory.
#
# Arguments:
# - dirn: a directory into where to search for test scripts
#
# Output:
# The test output format is compatible with TAP specification, revision 12.
#
export ROOT=${PWD}

_ntest=0
run ${*:-.}
echo "1..${_ntest}"
