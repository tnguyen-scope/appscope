#!/bin/bash
# 
# Cribl AppScope Command-Line Option Tests
#

declare -i ERR=0

ARCH=$(uname -m)

run() {
    CMD="$@"
    echo "  \`${CMD}\`"
    OUT=$(${CMD} 2>&1)
    RET=$?
}

outputs() {
    if ! grep "$1" <<< "$OUT" >/dev/null; then
        echo "    * Expected \"$1\" in output of \`$CMD\`"
        ERR+=1
    fi
}

doesnt_output() {
    if grep "$1" <<< "$OUT" >/dev/null; then
        echo "    * Didn't expect \"$1\" in output of \`$CMD\`"
        ERR+=1
    fi
}

returns() {
    if [ "$RET" != "$1" ]; then
        echo "    * Expected \`$CMD\` to return $1, got $RET"
        ERR+=1
    fi
}

echo "================================="
echo "    Command Line Options Test"
echo "================================="

run ./bin/linux/${ARCH}/ldscope
outputs "error: missing --attach option or EXECUTABLE"
outputs "Cribl AppScope"
returns 1

run ./bin/linux/${ARCH}/ldscope -z 
outputs "invalid option: -z"
returns 1

run ./bin/linux/${ARCH}/ldscope -u
doesnt_output "error:"
outputs "Cribl AppScope"
returns 0

run ./bin/linux/${ARCH}/ldscope --usage
doesnt_output "error:"
outputs "Cribl AppScope"
returns 0

run ./bin/linux/${ARCH}/ldscope -h
doesnt_output "error:"
outputs "Cribl AppScope"
outputs "OVERVIEW:"
outputs "CONFIGURATION:"
outputs "METRICS:"
outputs "EVENTS:"
outputs "PROTOCOL DETECTION:"
outputs "PAYLOAD EXTRACTION:"
returns 0

run ./bin/linux/${ARCH}/ldscope -h all
doesnt_output "error:"
outputs "Cribl AppScope"
outputs "OVERVIEW:"
outputs "CONFIGURATION:"
outputs "METRICS:"
outputs "EVENTS:"
outputs "PROTOCOL DETECTION:"
outputs "PAYLOAD EXTRACTION:"
returns 0

run ./bin/linux/${ARCH}/ldscope -h AlL
doesnt_output "error:"
outputs "Cribl AppScope"
outputs "OVERVIEW:"
outputs "CONFIGURATION:"
outputs "METRICS:"
outputs "EVENTS:"
outputs "PROTOCOL DETECTION:"
outputs "PAYLOAD EXTRACTION:"
returns 0

run ./bin/linux/${ARCH}/ldscope -h OvErViEw
doesnt_output "error:"
outputs "Cribl AppScope"
outputs "OVERVIEW:"
doesnt_output "CONFIGURATION:"
doesnt_output "METRICS:"
doesnt_output "EVENTS:"
doesnt_output "PROTOCOL DETECTION:"
doesnt_output "PAYLOAD EXTRACTION:"
returns 0

run ./bin/linux/${ARCH}/ldscope -h bogus
outputs "error: invalid help section"
outputs "Cribl AppScope"
returns 1

run ./bin/linux/${ARCH}/ldscope -l 
outputs "missing required value for -l option"
returns 1

run ./bin/linux/${ARCH}/ldscope -l /does_not_exist echo 
outputs "No such file or directory"
outputs "failed to extract"
returns 1

run ./bin/linux/${ARCH}/ldscope --libbasedir /does_not_exist echo 
outputs "No such file or directory"
outputs "failed to extract"
returns 1

run ./bin/linux/${ARCH}/ldscope -f /does_not_exist echo 
outputs "No such file or directory"
outputs "failed to extract"
returns 1

run ./bin/linux/${ARCH}/ldscope -a 
outputs "missing required value for -a option"
returns 1

if [ "0" == "$(id -u)" ]; then

    run ./bin/linux/${ARCH}/ldscope -a not_a_pid
    outputs "invalid --attach PID"
    returns 1

    run ./bin/linux/${ARCH}/ldscope -a -999
    outputs "invalid --attach PID"
    returns 1

    run ./bin/linux/${ARCH}/ldscope -a 999999999
    outputs "error: --attach PID not a current process"
    returns 1

else 

    run ./bin/linux/${ARCH}/ldscope -a 999999999
    outputs "error: --attach requires root"
    returns 1

fi

run ./bin/linux/${ARCH}/ldscope echo foo
outputs foo
returns 0

run ./bin/linux/${ARCH}/ldscopedyn
outputs "missing --attach or EXECUTABLE"
returns 1

run ./bin/linux/${ARCH}/ldscopedyn -z 
outputs "invalid option: -z"
returns 1

run ./bin/linux/${ARCH}/ldscopedyn echo
outputs "SCOPE_LIB_PATH must be set"
returns 1

export SCOPE_LIB_PATH=bogus
run ./bin/linux/${ARCH}/ldscopedyn echo
outputs "library bogus is missing"
returns 1
export -n SCOPE_LIB_PATH

export SCOPE_LIB_PATH=./lib/linux/${ARCH}/libscope.so
run ./bin/linux/${ARCH}/ldscopedyn echo
returns 0
export -n SCOPE_LIB_PATH

run ./bin/linux/${ARCH}/ldscopedyn --attach
outputs "missing value for -a option"
returns 1

run ./bin/linux/${ARCH}/ldscopedyn -a
outputs "missing value for -a option"
returns 1

export SCOPE_LIB_PATH=./lib/linux/${ARCH}/libscope.so
run ./bin/linux/${ARCH}/ldscopedyn -a 999999999
outputs "fopen(/proc/PID/maps) failed"
outputs "failed to find libc in target process"
returns 1
export -n SCOPE_LIB_PATH

export SCOPE_LIB_PATH=./lib/linux/${ARCH}/libscope.so
run ./bin/linux/${ARCH}/ldscopedyn -a 999999999 echo
outputs "ignoring EXECUTABLE argument with --attach option"
returns 1
export -n SCOPE_LIB_PATH

if [ $ERR -eq "0" ]; then
    echo "Success"
else
    echo "Test Failed"
fi

exit ${ERR}
