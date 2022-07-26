package main

Chip :: struct {
	input_pins:  []Value,
	output_pins: []Value,
	inner_pins:  [10]Value,
	bytecode:    []byte,
}

clone_chip :: proc(c: ^Chip, alloc := context.allocator) -> ^Chip {
	result := new_clone(
		Chip{
			input_pins = make([]Value, len(c.input_pins)),
			output_pins = make([]Value, len(c.output_pins)),
			bytecode = c.bytecode,
		},
	)
	copy(c.input_pins, result.input_pins)
	copy(c.output_pins, result.output_pins)
	return result
}

Value :: union {
	bool,
}

Op_Code :: enum byte {
	Op_Get,
	Op_Set,
	Op_Get_In,
	Op_Set_Out,
	Op_Nand,
	Op_And,
	Op_Or,
	Op_Not,
}

Vm :: struct {
	chip:  ^Chip,
	ip:    int,
	stack: [10]Value,
	count: int,
}

push :: proc(vm: ^Vm, v: Value) {
	vm.stack[vm.count] = v
	vm.count += 1
}

pop :: proc(vm: ^Vm) -> (out: Value) {
	out = vm.stack[vm.count - 1]
	vm.count -= 1
	return
}

get_byte :: proc(vm: ^Vm) -> byte {
	vm.ip += 1
	return vm.chip.bytecode[vm.ip - 1]
}

execute :: proc(chip: ^Chip) {
	vm := &Vm{chip = chip}
	for {
		op := Op_Code(get_byte(vm))

		switch op {
		case .Op_Get:
			addr := get_byte(vm)
			push(vm, vm.chip.inner_pins[addr])

		case .Op_Set:
			addr := get_byte(vm)
			vm.chip.inner_pins[addr] = pop(vm)

		case .Op_Get_In:
			addr := get_byte(vm)
			push(vm, vm.chip.input_pins[addr])

		case .Op_Set_Out:
			addr := get_byte(vm)
			vm.chip.output_pins[addr] = pop(vm)

		case .Op_Nand:
			a := pop(vm).(bool)
			b := pop(vm).(bool)
			push(vm, !(a & b))

		case .Op_And:
			a := pop(vm).(bool)
			b := pop(vm).(bool)
			push(vm, (a & b))
		case .Op_Or:
			a := pop(vm).(bool)
			b := pop(vm).(bool)
			push(vm, (a | b))
		case .Op_Not:
			a := pop(vm).(bool)
			push(vm, !(a))
		}

		if vm.ip >= len(chip.bytecode) {
			break
		}
	}
}


//odinfmt: disable
NAND_BYTECODE := [?]byte{
    byte(Op_Code.Op_Get_In), 0,
    byte(Op_Code.Op_Get_In), 1,
    byte(Op_Code.Op_Nand),
    byte(Op_Code.Op_Set_Out), 0,
}
AND_BYTECODE := [?]byte{
	byte(Op_Code.Op_Get_In), 0,
    byte(Op_Code.Op_Get_In), 1,
    byte(Op_Code.Op_And),
    byte(Op_Code.Op_Set_Out), 0,
}
OR_BYTECODE := [?]byte{
	byte(Op_Code.Op_Get_In), 0,
    byte(Op_Code.Op_Get_In), 1,
    byte(Op_Code.Op_Or),
    byte(Op_Code.Op_Set_Out), 0,
}
NOT_BYTECODE := [?]byte{
	byte(Op_Code.Op_Get_In), 0,
    byte(Op_Code.Op_Not),
    byte(Op_Code.Op_Set_Out), 0,
}
//odinfmt: enable
