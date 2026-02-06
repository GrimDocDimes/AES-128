# AES-128 Cryptographic Accelerator

A fully synthesizable hardware implementation of AES-128 encryption from RTL to GDSII using the OpenLane ASIC toolchain.

## Overview

This project implements a complete AES-128 encryption accelerator with:
- **128-bit plaintext input**
- **128-bit secret key**
- **128-bit ciphertext output**
- **Fully combinational design** (single-cycle encryption)
- **Verified against NIST FIPS-197 test vectors**

## Architecture

The design consists of three main modules:

1. **aes_sbox.v** - S-box lookup table for SubBytes transformation
2. **aes_key_expand.v** - Key expansion module generating 11 round keys
3. **aes128.v** - Top-level encryption module with:
   - SubBytes: Byte substitution using S-box
   - ShiftRows: Row permutation
   - MixColumns: Column mixing (rounds 1-9)
   - AddRoundKey: Round key XOR operation

The AES-128 algorithm performs 10 rounds of encryption transformations.

## Directory Structure

```
aes128/
├── src/
│   ├── aes128.v          # Top-level AES module
│   ├── aes_sbox.v        # S-box lookup table
│   ├── aes_key_expand.v  # Key expansion
│   └── tb_aes128.v       # Testbench
├── config.json           # OpenLane configuration
└── README.md             # This file
```

## RTL Simulation

### Prerequisites
- iverilog (Icarus Verilog)
- gtkwave (waveform viewer)
- OpenLane (for synthesis and physical design)

### Running Simulation

```bash
# Compile and simulate
cd /home/jhush/aes128
iverilog -o aes128_tb src/aes128.v src/aes_sbox.v src/aes_key_expand.v src/tb_aes128.v
vvp aes128_tb

# View waveforms
gtkwave aes128.vcd
```

### Test Results

All NIST FIPS-197 test vectors pass:
- ✅ NIST FIPS-197 Appendix C.1
- ✅ All zeros plaintext/key
- ✅ Additional random patterns

## OpenLane ASIC Flow

### Prerequisites

Ensure OpenLane is installed. Default path assumed: `/run/media/jhush/NEWTING/OpenLane`

### Synthesis Only

```bash
cd /run/media/jhush/NEWTING/OpenLane
make mount

# Inside container
yosys
read_verilog designs/aes128/src/aes128.v designs/aes128/src/aes_sbox.v designs/aes128/src/aes_key_expand.v
hierarchy -top aes128
synth
stat
exit
```

### Full RTL → GDS Flow

```bash
# Copy design to OpenLane designs directory
cp -r /home/jhush/aes128 /run/media/jhush/NEWTING/OpenLane/designs/

# Enter OpenLane container
cd /run/media/jhush/NEWTING/OpenLane
make mount

# Run full flow
./flow.tcl -design aes128 -tag aes128_run -overwrite
```

### View Results

```bash
# Inside container - check metrics
cd designs/aes128/runs/aes128_run
column -s, -t reports/metrics.csv | less

# DRC check
cd results/final
magic -T sky130A.tech lef/aes128.lef gds/aes128.gds
# In Magic: drc check

# LVS check
netgen -batch lvs \
  "gds/aes128.gds aes128" \
  "verilog/aes128.v aes128" \
  sky130A_setup.tcl lvs.out

# Exit container and view final GDS
exit
cd /run/media/jhush/NEWTING/OpenLane/designs/aes128/runs/aes128_run
klayout results/final/gds/aes128.gds
```

## Design Specifications

- **Technology**: SKY130 PDK
- **Clock Target**: 100 MHz (10ns period)
- **Design Type**: Combinational (no clock required for current implementation)
- **Optimization**: Area optimized
- **Standard Cell Library**: sky130_fd_sc_hd

## Verification

The design has been verified with:
1. ✅ Functional simulation with NIST test vectors
2. ⏳ Synthesis (pending OpenLane run)
3. ⏳ DRC checks (pending OpenLane run)
4. ⏳ LVS verification (pending OpenLane run)

## References

- [NIST FIPS-197: AES Specification](https://csrc.nist.gov/publications/detail/fips/197/final)
- [OpenLane Documentation](https://openlane.readthedocs.io/)
- [SKY130 PDK](https://skywater-pdk.readthedocs.io/)

## Next Steps

1. Run full OpenLane synthesis and place-and-route
2. Perform DRC and LVS verification
3. Analyze timing, area, and power metrics
4. Generate final GDSII for fabrication

## License

This is an educational/research implementation of AES-128 for ASIC design learning purposes.
