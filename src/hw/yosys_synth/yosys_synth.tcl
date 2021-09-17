yosys -import

# Read in the design
read_verilog $::env(SYNTH)/$::env(RV_ARCH)_rtl_sources/*.v

# Synthesise processes ready for SCC check.
procs

# Check that there are no logic loops in the design early on.
tee -o $::env(SYNTH)/logic-loops.rpt check -assert

# Generic yosys synthesis command
synth -top $::env(SYN_MODULE)

# Print some statistics out
tee -o $::env(SYNTH)/synth-statistics-ltp-$::env(RV_ARCH)-$::env(SYN_MODULE).rpt stat -tech cmos
tee -o $::env(SYNTH)/synth-ltp-$::env(RV_ARCH)-$::env(SYN_MODULE).rpt ltp -noff

# Write out the synthesised verilog
write_verilog $::env(SYNTH)/synth-$::env(RV_ARCH)-$::env(SYN_MODULE).v

