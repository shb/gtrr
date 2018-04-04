#!/bin/sh

BEFORE_ALL=before.all
BEFORE_EACH=before.each
TESTS='*.test'
RUNNER=source
BUFFER=1
AFTER_ALL=after.all
AFTER_EACH=after.each

# Used only for development, at the moment
VERBOSE=0

gtrr_error () {
	echo "Bail out! $1"
	exit 1
}

gtrr_debug () {
	if [ "${VERBOSE}" != "0" ]; then
		echo "# $*"
	fi
}

gtrr_run () {
	# Cache program vars for restoring them afterwards
	#TODO: this may be made simpler by defining **global defaults** and assign **local values**
	local _BEFORE_ALL=$BEFORE_ALL
	local _BEFORE_EACH=$BEFORE_EACH
	local _TESTS=$TESTS
	local _RUNNER=$RUNNER
	local _BUFFER=$BUFFER
	local _AFTER_ALL=$AFTER_ALL
	local _AFTER_EACH=$AFTER_EACH

	for batch in "$@"; do
		if [ -d "${batch}" ]; then
			local _pdir_=${PWD}
			gtrr_debug "cd '${batch}'"
			cd "${batch}"
			local _cwd_=${PWD}
			if [ -r "${BEFORE_ALL}" ]; then
				gtrr_debug "source ${PWD}/${BEFORE_ALL}"
				if source "./${BEFORE_ALL}"; then true; else gtrr_error "Batch setup failed"; fi
			fi

			for TEST in "${_cwd_}"/$TESTS; do
				if [ -r "${TEST}" ]; then
					TEST_NAME=$(basename "${TEST}")
					#TEST=${_cwd_}/${TEST}
					if [ -d "${TEST}" ]; then
						gtrr_debug "run '${TEST}'"
						gtrr_run "${TEST}"
					else
						if [ -r "${_cwd_}/${BEFORE_EACH}" ]; then
							gtrr_debug "source '${_cwd_}/${BEFORE_EACH}'"
							if source "${_cwd_}/${BEFORE_EACH}"; then true; else gtrr_error "Test setup failed"; fi
						fi
						local OK=${_ntest}
						gtrr_debug "${RUNNER} '${TEST}'"
						if [ "x$BUFFER" != "x" ]; then
							${RUNNER} "${TEST}" 1> "${ROOT}/.gtrr_out"
						else
							${RUNNER} "${TEST}"
						fi
						OK=$?
						let _ntest++
						if [ -r "${AFTER_EACH}" ]; then
							gtrr_debug "source '${PWD}/${AFTER_EACH}'"
							if source "./${AFTER_EACH}"; then true; else gtrr_error "Test teardown failed"; fi
						fi
						if [ "${OK}" == "0" ]; then
							echo "ok ${_ntest} - ${TEST_NAME}"
						else
							if [ "x$BUFFER" != "x" ]; then cat "${ROOT}/.gtrr_out"; fi
							echo "not ok ${_ntest} - ${TEST_NAME}"
						fi
					fi
				fi
			done

			if [ -r "${AFTER_ALL}" ]; then
				gtrr_debug "source '${PWD}/${AFTER_ALL}'"
				if source "./${AFTER_ALL}"; then true; else gtrr_error "Batch teardown failed"; fi
			fi

			gtrr_debug "cd '${_pdir_}'"
			cd "${_pdir_}"
		fi
	done

	BEFORE_ALL=$_BEFORE_ALL
	BEFORE_EACH=$_BEFORE_EACH
	TESTS=$_TESTS
	RUNNER=$_RUNNER
	BUFFER=$_BUFFER
	AFTER_ALL=$_AFTER_ALL
	AFTER_EACH=$_AFTER_EACH
}

#
# Command: gtrr
#
# Run one or more test suites
#
# --- Prototype ---
# gtrr [dir1] [dir2] ...
# -----------------
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
# by calling the `gtrr_run` command inside the needed per- or post- requisite
# script.
#
# Setup of the whol test run can be pu inside a before-all script in the
# first or top-level test batch directory.
#
# Parameters:
# 	dirn - one or more directories into where to search for test scripts
#
# Returned values:
# The test output format is compatible with TAP specification, revision 12.
#
_ROOT=$ROOT
export ROOT=${PWD}

_ntest=0
gtrr_run "${*:-.}"
_ok=$?
if [ "${_ntest}" == "0" ]; then
	gtrr_error "No test found"
else
	echo "1..${_ntest}"
fi

# Restore whatever the previous value of env ROOT was
export ROOT=$_ROOT

exit $_ok
