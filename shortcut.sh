# Explicit compiler shortcut; do not silently replace gcc/clang with ccache.
alias iree-cpu='iree-compile --iree-hal-target-backends=llvm-cpu --iree-llvmcpu-target-cpu=host'
