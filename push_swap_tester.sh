#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# General-purpose test function (shows command and output)
run_test() {
    local desc="$1"
    local cmd="$2"
    local expect="$3"

    echo -e "\n${CYAN}> Running test: ${YELLOW}$desc${NC}"
    echo "  Command: $cmd"

    output=$(eval "$cmd" 2>&1)
    if [[ -z "$output" ]]; then
        echo "  Output: (empty)"
    else
        echo "  Output: '$output'"
    fi

    if [[ "$output" == "$expect" ]]; then
        echo -e "  Result: ${GREEN}PASS${NC}"
    else
        echo -e "  Result: ${RED}FAIL${NC}"
        echo "  Expected: '$expect'"
    fi
}

# Specialized test for checker/sorting scenarios
run_checker_test() {
    local desc="$1"
    local arg="$2"
    local expected_checker="$3"
    local max_instructions="$4"

    echo -e "\n${CYAN}> Running test: ${YELLOW}$desc${NC}"
    echo "  Input: $arg"

    instructions=$(./push_swap $arg)
    checker_output=$(echo "$instructions" | ./checker_linux $arg)

    if [[ -z "$instructions" ]]; then
        instr_count=0
    else
        instr_count=$(echo "$instructions" | wc -l)
    fi

    echo "  push_swap output:"
    if [[ -z "$instructions" ]]; then
        echo "    (no instructions)"
    else
        echo "$instructions" | sed 's/^/    /'
    fi
    echo "  checker output: $checker_output"
    echo -e "  instructions: ${GREEN}$instr_count${NC}"

    if [[ "$checker_output" == "$expected_checker" && "$instr_count" -le "$max_instructions" ]]; then
        echo -e "  Result: ${GREEN}PASS${NC}"
    else
        echo -e "  Result: ${RED}FAIL${NC}"
    fi
}


echo "=== Error management tests ==="
run_test "non-numeric parameter" "./push_swap 2 4 1 d 7" "Error"
run_test "duplicate number" "./push_swap 2 4 1 4 7" "Error"
run_test "number > MAXINT (2147483648)" "./push_swap 2147483648" "Error"
run_test "no parameters (expect no output)" "./push_swap" ""

echo -e "\n=== Identity tests ==="
run_test "single '42'" "./push_swap 42" ""
run_test "already sorted '0 1 2 3'" "./push_swap 0 1 2 3" ""
run_test "already sorted 10 numbers" "./push_swap 0 1 2 3 4 5 6 7 8 9" ""

echo -e "\n=== Simple version tests ==="
run_checker_test "small sort (2 1 0)" "2 1 0" "OK" 3
run_checker_test "small sort (1 5 2 4 3)" "1 5 2 4 3" "OK" 8

echo -e "\n=== Randomized tests ==="
for n in 5 100 500; do
    echo -e "\n${CYAN}> Running random test for $n numbers...${NC}"
    ARG=$(shuf -i 0-$((n - 1)) -n $n | tr '\n' ' ')
    instructions=$(./push_swap $ARG)
    checker_output=$(echo "$instructions" | ./checker_linux $ARG)
    instr_count=$(echo "$instructions" | wc -l)
    if [[ "$n" -eq 5 ]]; then
        echo "  args: $ARG"
        echo "  push_swap output:"
        if [[ -z "$instructions" ]]; then
            echo "    (no instructions)"
        else
            echo "$instructions" | sed 's/^/    /'
        fi
    fi
    echo "  checker output: $checker_output"
    echo -e "  instructions: ${GREEN}$instr_count${NC}"
    if [[ "$checker_output" == "OK" ]]; then
        echo -e "  Result: ${GREEN}PASS${NC}"
    else
        echo -e "  Result: ${RED}FAIL${NC}"
    fi
done
