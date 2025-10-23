#!/bin/bash

PUSH_SWAP=./push_swap
CHECKER=./checker_linux

# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m"

echo "=== Error management tests ==="

run_test() {
    local desc="$1"
    local cmd="$2"
    local expect="$3"

    output=$(eval "$cmd" 2>&1)
    if [[ "$output" == "$expect" ]]; then
        echo -e "TEST: $desc ... ${GREEN}PASS${NC}"
    else
        echo -e "TEST: $desc ... ${RED}FAIL${NC}"
        echo "    -> got: '$output'"
    fi
}

# Error handling tests
run_test "non-numeric parameter" "$PUSH_SWAP 2 4 1 d 7" "Error"
run_test "duplicate number" "$PUSH_SWAP 2 4 1 4 7" "Error"
run_test "number > MAXINT (2147483648)" "$PUSH_SWAP 2147483648" "Error"

output=$($PUSH_SWAP)
if [[ -z "$output" ]]; then
    echo -e "TEST: no parameters (expect no output) ... ${GREEN}PASS${NC}"
else
    echo -e "TEST: no parameters (expect no output) ... ${RED}FAIL${NC}"
fi

echo
echo "=== Identity tests (should produce no instructions) ==="
for args in "42" "0 1 2 3" "0 1 2 3 4 5 6 7 8 9"; do
    output=$($PUSH_SWAP $args)
    if [[ -z "$output" ]]; then
        echo -e "TEST: $args ... ${GREEN}PASS${NC}"
    else
        echo -e "TEST: $args ... ${RED}FAIL${NC}"
    fi
done

echo
echo "=== Simple version tests ==="
ARG="2 1 0"
instructions=$($PUSH_SWAP $ARG | tee /tmp/instructions.txt)
result=$($CHECKER $ARG < /tmp/instructions.txt)
count=$(wc -l < /tmp/instructions.txt)
if [[ "$result" == "OK" && $count -ge 2 && $count -le 3 ]]; then
    echo -e "Test ARG='$ARG' -> checker: $result, instructions: ${GREEN}$count${NC} ... ${GREEN}PASS${NC}"
else
    echo -e "Test ARG='$ARG' -> checker: $result, instructions: ${RED}$count${NC} ... ${RED}FAIL${NC}"
fi

echo
echo "=== Another simple version ==="
ARG="1 5 2 4 3"
instructions=$($PUSH_SWAP $ARG | tee /tmp/instructions.txt)
result=$($CHECKER $ARG < /tmp/instructions.txt)
count=$(wc -l < /tmp/instructions.txt)
if [[ "$result" == "OK" && $count -le 12 ]]; then
    echo -e "Test ARG='$ARG' -> checker: $result, instructions: ${GREEN}$count${NC} ... ${GREEN}PASS${NC}"
else
    echo -e "Test ARG='$ARG' -> checker: $result, instructions: ${RED}$count${NC} ... ${RED}FAIL${NC}"
fi

echo "Running 5-random-values test (3 permutations)..."
for i in {1..3}; do
    ARG=$(shuf -i 0-99 -n 5 | tr '\n' ' ')
    instructions=$($PUSH_SWAP $ARG | tee /tmp/instructions.txt)
    result=$($CHECKER $ARG < /tmp/instructions.txt)
    count=$(wc -l < /tmp/instructions.txt)
    if [[ "$result" == "OK" && $count -le 12 ]]; then
        echo -e "  $i) ARG='$ARG' -> checker: $result, instructions: ${GREEN}$count${NC} ... ${GREEN}PASS${NC}"
    else
        echo -e "  $i) ARG='$ARG' -> checker: $result, instructions: ${RED}$count${NC} ... ${RED}FAIL${NC}"
        echo "    -> checker output: $result"
        echo "    -> instructions: $count"
        echo "    -> instructions file contents:"
        cat /tmp/instructions.txt
    fi
done

echo
echo "=== Middle version (100 random values) ==="
ARG=$(shuf -i 0-999 -n 100 | tr '\n' ' ')
instructions=$($PUSH_SWAP $ARG | tee /tmp/instructions.txt)
result=$($CHECKER $ARG < /tmp/instructions.txt)
count=$(wc -l < /tmp/instructions.txt)
if [[ "$result" == "OK" ]]; then
    echo -e "ARG=100-random -> checker: $result, instructions: ${GREEN}$count${NC}"
    if   [[ $count -lt 700 ]];  then echo -e "Result: ${GREEN}5${NC}"
    elif [[ $count -lt 900 ]];  then echo -e "Result: ${GREEN}4${NC}"
    elif [[ $count -lt 1100 ]]; then echo -e "Result: ${GREEN}3${NC}"
    elif [[ $count -lt 1300 ]]; then echo -e "Result: ${GREEN}2${NC}"
    elif [[ $count -lt 1500 ]]; then echo -e "Result: ${GREEN}1${NC}"
    else echo -e "Result: ${RED}0${NC}"
    fi
else
    echo -e "ARG=100-random -> checker: ${RED}$result${NC}, instructions: ${RED}$count${NC}"
    echo -e "Result: ${RED}FAIL (checker did not return OK)${NC}"
fi

echo
echo "=== Advanced version (500 random values) ==="
ARG=$(shuf -i 0-9999 -n 500 | tr '\n' ' ')
instructions=$($PUSH_SWAP $ARG | tee /tmp/instructions.txt)
result=$($CHECKER $ARG < /tmp/instructions.txt)
count=$(wc -l < /tmp/instructions.txt)
if [[ "$result" == "OK" ]]; then
    echo -e "ARG=500-random -> checker: $result, instructions: ${GREEN}$count${NC}"
    if   [[ $count -lt 5500 ]];  then echo -e "Result: ${GREEN}5${NC}"
    elif [[ $count -lt 7000 ]];  then echo -e "Result: ${GREEN}4${NC}"
    elif [[ $count -lt 8500 ]];  then echo -e "Result: ${GREEN}3${NC}"
    elif [[ $count -lt 10000 ]]; then echo -e "Result: ${GREEN}2${NC}"
    elif [[ $count -lt 11500 ]]; then echo -e "Result: ${GREEN}1${NC}"
    else echo -e "Result: ${RED}0${NC}"
    fi
else
    echo -e "ARG=500-random -> checker: ${RED}$result${NC}, instructions: ${RED}$count${NC}"
    echo -e "Result: ${RED}FAIL (checker did not return OK)${NC}"
fi

echo
echo "=== Done ==="
