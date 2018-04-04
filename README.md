Generic Test Runner and Reporter
================================

**GTRR** recursively runs test scripts from directories and report their result
in TAP format. The test result is defined as the status code returned from the
test script.

It can execute setup and teardown scripts before and after each test, and before
and after each test script directory is traversed. Through shell scripting and
file structure, GTRR does what tools like Jasmin do in code, with the added
convenience that, being run from the shell, the test can be any program in any
language or testing framework. Moreover, the test scripts discovery and execution
behavior of GTRR can be customized for any sub-tree of the test directory tree.


Quickstart
----------

Run with:

    bin/gtrr.sh test_dir_1 test_dir_2 ...

It will execute all the `*.test` files found in the mentioned directories as
shell scripts.

If present, it will execute `before.each` and `after.each` script before and
after every test script.

If present, it will execute `before.all` and `after.all` scripts once before
and after all the test script are run.


Test batch execution environment
--------------------------------

Every directory scanned and run by gtrr constitutes a _test batch_. Every test
script in a batch is run with the batch directory set as cwd (which can be read
from the env variable `$PWD`). The starting working directory from where gtrr
was invoked is stored in env variable `$ROOT` (TODO: this should be changed to
something more specific).

Test batch execution details can be tweaked by changing some system variables.
All changes are valid for the current batch only, and are reverted to the
prevous values when exiting the batch. They can be visible though from sub-batches.

### Test script pattern
The glob pattern with which the test scripts from a test directory are found
can be changed setting the global variable `$TESTS` inside _before_ and _after_
scripts.

### Test script runner
The program to run test script can be changed by changin the `$RUNNER` variable.
Its default value is `source`, so test scripts (as before and after scripts)
are run inside the gtrr shell process, with the ability of sharing variables
between scripts.

### Before and after scripts
The file name for before and after scripts can also be changed by assigning the
name to the variables `BEFORE_ALL`, `BEFORE_EACH`, `AFTER_EACH`, `AFTER_ALL`.
