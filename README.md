# Processor Design Project
Computer architecture course lab based CPU design project in VHDL


<p align="center">
  <img width="700" height="402" src="https://raw.githubusercontent.com/KyleCathers/Processor-Design-Project/master/FPGA%20%26%20STM.png">
</p>

# Project Description
Design and implement a 16-bit CPU

## Instructions Set:

We use a RISC-like instruction set in the project. Instructions are 1 - word ( 16-
bits) long and are word aligned. There are eight 16-bit general purpose registers; R0, R1,
… R7. R7 has also some additional special roles. It acts as a link register to receive the
program counter for the branch-to-subroutine (procedure) instruction. It is also the target
for the load-immediate instruction. The memory address space is 216= 65,536 bytes and
it is byte addressable.

### 1) A Format
These instructions are 2-byte long. The Op-code is
the 7 most significant bits i.e. bits 15 to 9 while the remaining 9 bits are divided into three
fields that determine operand registers.

The instruction set file shows the op-code values for a-format instructions and explains their
functionality. R[ra] indicates value of register ra. A special TEST instruction
determines whether a specific register’s contents are zero, positive or negative. Please note
that there is no functionality that stores or restores the contents of the zero (Z) or negative
(N) flags explicitly. However, in the project extension, interrupt handling requires the
saving and restoring the processor state including the N and Z flags. . The TEST
instruction, is meant to be issued before a conditional branch to set the conditions for this
branch. The processor has a 16-bit input port and a 16-bit output port. The ports of the
processor are connected to external pins. IN, and OUT instructions transfer values
between the processor ports and the internal registers.

As an example, the ADD r3, r2, r1 instruction, has the following op-code, ra, rb and rc
fields: op-code = 1, ra = 3, rb = 2, rc=1

The bit stream for the instruction is: 0000001011010001. Hence, the hexadecimal
format of the instruction is: 0x02D1


### 2) B Format
B-format instructions are are used for branch instructions. As the instruction set shows,
the Bformat determines a (relative) displacement and for the second format, a register.
There are two different types. The first is branch relative (BRR). This indicates that the branch is
relative to the program counter (PC). The branch can be forward when the displacement is
positive or backwards when the displacement is negative. Note the two’s complement
arithmetic and the fact that the displacement is always multiplied by two to ensure word
(two-byte) alignment.
The alternate type, is branch absolute (BR). In this case, the base target address is stored in
one of the registers while the target address is formed when the displacement (multiplied
by two) is added to the base address. The base address is assumed to be word aligned i.e.
the least significant bit is zero2.
BR.Z(N) are conditional branches. If the Z(N) flag is one, the branch is taken otherwise, it
is not. BR.SUB is used for a subroutine call. It saves the address of the next instruction
into register r7 and branches to the address of subroutine formed by the addition of the
contents of the specified register plus the stated displacement. At the end of subroutine, a
RETURN instruction copies the contents of r7 into the PC .
Note that branching to a subroutine, does not save any state except the program counter.

### 3) L Format

L-format instructions are used for loads, stores and moves. These are two-operand
instructions defining a source and a destination. There are of two types: immediate and
to/from register. The immediate load, loads one (immediate) byte to the MSB or LSB
part of register r7. The immediate loads are used to formulate effective addresses in r7.
This introduces an asymmetry in the ISA, but such a format was used to ensure that all
instructions are of the same length (i.e. 2 bytes) and therefore simplify (and hence
speed-up) the design of the instruction pipeline.
The to/from register format defines the register holding the effective address and the
register that will receive the data from memory or holds the data to be moved to
memory (or to another register in the case of MOVE).
are two bytes and are used for load/store instructions. The first byte holds op-code and ra and
the second byte holds address of memory or an immediate value. Figure 3 shows the L-format
instructions. Note that in L-format instructions, the first three low order bits of the first byte are
unused.

The instruction set shows details of L-format instructions. LOAD and STORE instructions
write/read register ra into/from address ea. M[ea] shows the content of memory with
address ea. LOADIMM writes a constant value (imm) into register ra.

### Comments on the system architecture - RAM
• A dual ported RAM is used to ensure that instruction and data traffic is separated (Harvard
architecture)

• The RAM serializes the access requests arbitrarily.

• The suggested (slide 9) RAM implementation is a synchronous one and it allows the specification of
the delay (in clock cycles) of the read data to appear on the data_out port of the RAM.

### Comments on the system architecture - ROM
• ROM is used to store a rudimental BIOS.

• The main functionality of the BIOS is: 1) Load user code into the appropriate location in
RAM 2) Execute user code

### Resets
• The two resets implement the load and execute functionality of the BIOS

• Both clear the PC

• Reset and Execute vectors to address 0x0000 while Reset and Load vectors to address 0x0002.

• At each address, the developer has introduced the appropriate branch (BRR) instruction that
vectors to the reset-handling routine (this is part of the BIOS)

### ROM, RAM and ports
• ROM is 1024-byte large starting at address 0x0000

• RAM is a 1024 byte block starting at address 0x0400

• We use memory-mapped ports. The input port is located at 0xFFF0 while the output port is at 0xFFF2

### RAM module
• Please use the dual port distributed RAM macro XPM_MEMORY_DPDISTRAM from Xilinx XPM macro group

• This macro can configure a dual ported memory where port A can be used for both reading and writing 
while port B can only be used for reading only (from memory).
