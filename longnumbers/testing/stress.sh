#!/usr/bin/bash

test_mul=true
test_sub=true
test_add=true
test=0
while [ $test -lt 1000 ]; do
	./gen.py >test.txt
	if [ $test_mul ]; then
		./mul <test.txt >result_mul.txt
		./mul.py <test.txt >ans_mul.txt
		echo >>result_mul.txt
		cmp ans_mul.txt result_mul.txt
		if [ $? -ne 0 ]; then
			echo "Test $test mul failed!"
			exit 1
		fi
	fi

	if [ $test_sub ]; then
		./sub <test.txt >result_sub.txt
		./sub.py <test.txt >ans_sub.txt
		echo >>result_sub.txt
		cmp ans_sub.txt result_sub.txt
		if [ $? -ne 0 ]; then
			echo "Test $test sub failed!"
			exit 1
		fi
	fi

	if [ $test_add ]; then
		./add <test.txt >result_add.txt
		./add.py <test.txt >ans_add.txt
		echo >>result_add.txt
		cmp ans_add.txt result_add.txt
		if [ $? -ne 0 ]; then
			echo "Test $test add failed!"
			exit 1
		fi
	fi

	echo "Test $test passed."
	let "test += 1"
done
