#!/bin/bash

basedir=$(dirname "$0")
if [[ $@ == *"gdb"* ]]; then
	qemu-system-aarch64 -machine raspi3 -nographic -serial null -serial mon:stdio -m size=1G -kernel $basedir/kernel.img -S -gdb tcp::1234
else
	qemu-system-aarch64 -machine raspi3 -nographic -serial null -serial mon:stdio -m size=1G -kernel $basedir/kernel.img
fi
