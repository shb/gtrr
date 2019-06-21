#!/usr/bin/env sh

BEFORE_ALL=before.all
BEFORE_EACH=before.each
TESTS='*.test'
RUNNER=source
BUFFER=1
AFTER_ALL=after.all
AFTER_EACH=after.each

# Used only for development, at the moment
VERBOSE=0

GTRR_OUT=.gtrr_out
GTRR_ENV=.gtrr_env

gtrr_error () {
	echo "Bail out! $1"
	exit 1
}

gtrr_debug () {
	if [ "${VERBOSE}" != "0" ]; then
		echo "# $*"
	fi
}

gtrr_run_test () {
	local _pwd=${PWD}

	gtrr_debug "cd '${GTRR_TEST_DIR}'"
	cd "${GTRR_TEST_DIR}"

	gtrr_debug "export -p > '${GTRR_ENV}'"
	export -p > ${GTRR_ENV}

	export GTRR_TEST=$1
	export GTRR_TEST_NAME=$(basename "${GTRR_TEST}" | cut -f1 -d. )
	local GTRR_TEST_DIR=$(dirname "${GTRR_TEST}")
	export GTRR_TODO
	export GTRR_SKIP

	if [ -r "${GTRR_TEST_DIR}/${BEFORE_EACH}" ]; then
		gtrr_debug "source '${GTRR_TEST_DIR}/${BEFORE_EACH}'"
		if source "${GTRR_TEST_DIR}/${BEFORE_EACH}"; then true; else gtrr_error "Test setup failed"; fi
	fi
	local OK=${_ntest}
	gtrr_debug "${RUNNER} '${GTRR_TEST}'"
	if [ "x${BUFFER}" != "x" ]; then
		${RUNNER} "${GTRR_TEST}" 1> "${GTRR_TEST_DIR}/.gtrr_out"
	else
		${RUNNER} "${GTRR_TEST}"
	fi
	status=$?
	let _ntest++
	if [ -r "${GTRR_TEST_DIR}/${AFTER_EACH}" ]; then
		gtrr_debug "source '${GTRR_TEST_DIR}/${AFTER_EACH}'"
		if source "${GTRR_TEST_DIR}/${AFTER_EACH}"; then true; else gtrr_error "Test teardown failed"; fi
	fi

	# Eval possible TODO or SKIP directives
	local _directive=""
	if [ "x${GTRR_SKIP}" != "x" ]; then
		_directive=" # SKIP ${GTRR_SKIP}"
	elif [ "x${GTRR_TODO}" != "x" ]; then
		_directive=" # TODO ${GTRR_TODO}"
	fi

	if [ "${status}" == "0" ]; then
		echo "ok ${_ntest} - ${GTRR_TEST_NAME}${_directive}"
	else
		if [ "x${BUFFER}" != "x" ]; then cat "${GTRR_TEST_DIR}/${GTRR_OUT}"; fi
		echo "not ok ${_ntest} - ${GTRR_TEST_NAME}${_directive}"
	fi

	# Reconstruct original environment
	unset GTRR_SKIP
	unset GTRR_TODO
	unset GTRR_TEST_NAME
	unset GTRR_TEST
	gtrr_debug "source './${GTRR_ENV}'"
	source "./${GTRR_ENV}"

	# Return to starting directory
	gtrr_debug "cd '${_pwd}'"
	cd "${_pwd}"

	return $status
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

	local _overall_status=0
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

			let _exit_Status=0
			for TEST in "${_cwd_}"/$TESTS; do
				if [ -r "${TEST}" ]; then
					if [ -d "${TEST}" ]; then
						gtrr_debug "run '${TEST}'"
						gtrr_run "${TEST}"
						_exit_status=$?
					else
						gtrr_debug "gtrr_run_test '${TEST}'"
						gtrr_run_test "${TEST}"
						_exit_status=$?
					fi
				fi
			done
			if [ "$_exit_status" != "0" ]; then
				_overall_status=1
			fi

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

	return $_overall_status
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
# App env variables: since 0.2.0
_GTRR_ROOT=${GTRR_ROOT}
export GTRR_ROOT=$ROOT

_ntest=0
gtrr_debug "gtrr_run '${*:-.}'"
gtrr_run "${*:-.}"
_ok=$?
if [ "${_ntest}" == "0" ]; then
	gtrr_error "No test found"
else
	echo "1..${_ntest}"
fi

# Restore whatever the previous value of env ROOT was
ROOT=$_ROOT
GTRR_ROOT=$_GTRR_ROOT

exit $_ok
