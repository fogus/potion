#!/bin/sh
# test some compiler configurations on this platform (linux, darwin, win)
# cannot test cross with this yet
if [ -z $CCS ]; then
case `uname -o` in
*Linux) CCS="clang clang-3.3 gcc gcc-4.4 gcc-4.5 gcc-4.6 gcc-4.7 gcc-4.8" ;;
Darwin) CCS="clang clang-3.2 clang-mp-3.3 gcc gcc-mp-4.3 gcc-mp-4.8 gcc-mp-4.9" ;;
Cygwin) CCS="clang gcc gcc-3" ;;
esac
fi

cp config.inc config.inc.test
testdebug() {
    make -s realclean
    echo make CC="$1" DEBUG=$2
    make -s CC="$1" DEBUG=$2 >/dev/null 2>/dev/null
    make -s bin/potion bin/potion-test >/dev/null 2>/dev/null
    make -s bin/p2 bin/p2-test >/dev/null 2>/dev/null
    make test.pn; make test.p2
    echo make CC="$1" DEBUG=$2
    echo ---------------------
}

dotest() {
    testdebug "$1" 0
    testdebug "$1" 1
}

for c in $CCS
do
    dotest "$c"
done

testdebug "gcc -m32" 0
if [ `uname -o` = Darwin ]; then
    DYLD_LIBRARY_PATH=/usr/local/lib32 testdebug "gcc -m32" 1
fi

if test -f /opt/intel/bin/icc; then
    case `uname -m` in
        x86_64) /opt/intel/bin/compilervars.sh intel64
            ;;
        i386)   /opt/intel/bin/compilervars.sh ia32
            ;;
    esac
    dotest icc
fi

cp config.inc.test config.inc
make
