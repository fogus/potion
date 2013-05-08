#!/bin/sh
# usage: test/runtests.sh [testfile]
#        cmd="valgrind ./potion" test/runtests.sh

cmd=${cmd:-./potion}
ECHO=/bin/echo
SED=sed
EXPR=expr

count=0; failed=0; pass=0
EXT=pn;
cmdi="$cmd -I"; cmdx="$cmdi -X"; 
cmdc="$cmd -c"; extc=b

if test -z $1; then
    ${ECHO} running potion API tests; 
    test/api/potion-test; 
    ${ECHO} running GC tests; 
    test/api/gc-test; 
fi

while [ $pass -lt 3 ]; do 
    ${ECHO}; 
    if [ $pass -eq 0 ]; then 
	t=0; 
	whattests="$cmd VM tests"
    elif [ $pass -eq 1 ]; then 
        t=1; 
	whattests="$cmd compiler tests"
    elif [ $pass -eq 2 ]; then 
        t=2; 
	whattests="$cmd JIT tests"
	jit=`$cmd -v | sed "/jit=1/!d"`; 
	if [ "$jit" = "" ]; then 
	    pass=`expr $pass + 1`
	    break
	fi;
    fi

    if test -n "$1" && test -f "$1"; then
	what=$1
	if [ ${what%.pn} = $what -a $EXT = pn -a $pass -le 3 ]; then
	    ${ECHO} skipping potion
	    break
	fi
    else
	what=test/**/*.$EXT
    fi

    ${ECHO} running $whattests

    for f in $what; do 
	look=`cat $f | sed "/\#=>/!d; s/.*\#=> //"`
	#echo look=$look
	if [ $t -eq 0 ]; then
	    echo $cmdi -B $f
	    for=`$cmdi -B $f | sed "s/\n$//"`
	elif [ $t -eq 1 ]; then
	    echo $cmdc $f
	    $cmdc $f > /dev/null
	    fb=$f$extc
	    echo $cmdi -B $fb
	    for=`$cmdi -B $fb | sed "s/\n$//"`
	    rm -rf $fb
	else
	    echo $cmdx $f
	    for=`$cmdx $f | sed "s/\n$//"`
	fi;
	if [ "$look" != "$for" ]; then
	    ${ECHO}
	    ${ECHO} "** $f: expected <$look>, but got <$for>"
	    failed=`expr $failed + 1`
	else
	    # ${ECHO} -n .
	    jit=`$cmd -v | ${SED} "/jit=1/!d"`
	    if [ "$jit" = "" ]; then
		${ECHO} "* skipping"
		break
	    fi
	fi
	count=`expr $count + 1`
    done
    pass=`expr $pass + 1`
done

${ECHO}
if [ $failed -gt 0 ]; then
    ${ECHO} "$failed FAILS ($count tests)"
else
    ${ECHO} "OK ($count tests)"
fi
	    
