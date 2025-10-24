#!/bin/bash
> logs.txt
> valgrind.log

# ─── Color definitions ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# ─── Run valgrind on a command ───────────────────────────────────────────────
run_valgrind() {
    local cmd=("$@")
    echo -e "\nRunning valgrind on failing/passing-but-empty test: ${cmd[*]}"
    
    # Append to valgrind.log instead of overwriting
    {
        echo -e "\n--- Command: ${cmd[*]} ---"
        valgrind --leak-check=full --track-origins=yes --show-leak-kinds=all "${cmd[@]}"
    } >> valgrind.log 2>&1
}


# ─── General-purpose test function ───────────────────────────────────────────
run_test() {
    local desc="$1"
    local cmd="$2"
    local expect="$3"

    echo -e "\n${CYAN}> Running test: ${YELLOW}$desc${NC}"

    # Split command into array to handle negative numbers safely
    read -r -a cmd_array <<< "$cmd"
    output=$( "${cmd_array[@]}" 2>&1 )

    echo "  Command: $cmd"
    if [[ -z "$output" ]]; then
        echo "  Output: (empty)"
    else
        echo "  Output: '$output'"
    fi

    if [[ "$output" == "$expect" ]]; then
        echo -e "  Result: ${GREEN}PASS${NC}"
        # Run valgrind for expected error messages or empty output
        if [[ "$expect" == "Error" || -z "$expect" ]]; then
            run_valgrind "${cmd_array[@]}"
        fi
    else
        echo -e "  Result: ${RED}FAIL${NC}"
        echo "  Expected: '$expect'"
        run_valgrind "${cmd_array[@]}"
    fi
}


# ─── Checker-based test function ─────────────────────────────────────────────
run_checker_test() {
    local desc="$1"
    local arg="$2"
    local expected_checker="$3"
    local max_instructions="$4"

    echo -e "\n${CYAN}> Running test: ${YELLOW}$desc${NC}"

    read -r -a nums <<< "$arg"
    instructions=$(./push_swap "${nums[@]}")
    checker_output=$(echo "$instructions" | ./checker_linux "${nums[@]}")

    if [[ -z "$instructions" ]]; then
        instr_count=0
    else
        instr_count=$(echo "$instructions" | wc -l)
    fi

    echo "  Input: $arg"
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
        run_valgrind ./push_swap "${nums[@]}"
    fi
}

# ─── Random integer generator with bias ───────────────────────────────────────
generate_random_ints() {
    local count=$1
    declare -A seen
    nums=()

    while [ "${#nums[@]}" -lt "$count" ]; do
        if (( RANDOM % 10 < 9 )); then
            num=$((RANDOM % 2001 - 1000))
        else
            num=$(od -An -N4 -t d4 /dev/urandom | tr -d ' ')
        fi

        if [ "$num" -ge -2147483648 ] && [ "$num" -le 2147483647 ]; then
            if [ -z "${seen[$num]}" ]; then
                seen[$num]=1
                nums+=("$num")
            fi
        fi
    done

    echo "${nums[@]}"
}

# ─── Scoring thresholds based on 42 standards ────────────────────────────────
get_score() {
    local n=$1
    local instr_count=$2

    if [[ $n -eq 100 ]]; then
        if (( instr_count <= 700 )); then echo "5/5"
        elif (( instr_count <= 900 )); then echo "4/5"
        elif (( instr_count <= 1100 )); then echo "3/5"
        elif (( instr_count <= 1300 )); then echo "2/5"
        elif (( instr_count <= 1500 )); then echo "1/5"
        else echo "0/5"; fi
    elif [[ $n -eq 500 ]]; then
        if (( instr_count <= 5500 )); then echo "5/5"
        elif (( instr_count <= 7000 )); then echo "4/5"
        elif (( instr_count <= 8500 )); then echo "3/5"
        elif (( instr_count <= 10000 )); then echo "2/5"
        elif (( instr_count <= 11500 )); then echo "1/5"
        else echo "0/5"; fi
    fi
}

# ─── Fixed test suite ────────────────────────────────────────────────────────
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

# ─── Randomized tests (biased distribution) ──────────────────────────────────
# ─── Randomized tests (biased distribution) ──────────────────────────────────
echo -e "\n=== Randomized tests (2, 3, 4, 5, 100, 500 numbers) ==="

for n in 2 3 4 5 100 500; do
    echo -e "\n${CYAN}> Running random test with $n numbers (biased toward -1000→1000)${NC}"
    ARG=$(generate_random_ints $n)
    read -r -a nums <<< "$ARG"

    # Show sample
    if (( n <= 5 )); then
        echo "  Input sample: ${nums[*]}"
    else
        echo "  Input sample: ${nums[@]:0:10} ..."
    fi

    # Pipe directly to checker to handle empty output correctly
    checker_output=$(./push_swap "${nums[@]}" | ./checker_linux "${nums[@]}")
    instructions=$(./push_swap "${nums[@]}")
    instr_count=$(echo "$instructions" | wc -l)

    if (( n <= 5 )); then
        echo "  push_swap output:"
        echo "$instructions" | sed 's/^/    /'
    fi

    echo "  checker output: $checker_output"
    echo -e "  instructions: ${GREEN}$instr_count${NC}"

    # Score only for 100 and 500
    if (( n == 100 || n == 500 )); then
        score=$(get_score $n $instr_count)
        echo -e "  score: ${MAGENTA}$score${NC}"
        # Save logs
        echo "[${n}] ${nums[*]}" >> logs.txt
    fi

    # Determine pass/fail based on checker only
    if [[ "$checker_output" == "OK" ]]; then
        echo -e "  Result: ${GREEN}PASS${NC}"
    else
        echo -e "  Result: ${RED}FAIL${NC}"
        run_valgrind ./push_swap "${nums[@]}"
    fi
done

echo -e "\n=== Testing complete ==="
echo -e "${YELLOW}Logs saved to logs.txt for 100 and 500 input cases.${NC}"
echo -e "${YELLOW}Valgrind logs for failing cases saved to valgrind.log${NC}"