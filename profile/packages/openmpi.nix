# openmpi.nix —— OpenMPI 模块：MPI 并行编程环境（HPC/并行课程使用）。
# 被 default.nix 引入；toolchain-checks.nix 的 openmpi 检查会编译并双进程
#   运行 MPI Allreduce 程序做端到端验证。
{ pkgs }:
{
  # Compiler wrappers and mpi.h are in dev, mpirun/mpiexec are in out.
  packages = [
    pkgs.openmpi
    # 同时安装两个输出：out 提供 mpirun/mpiexec 运行时，
    # dev 提供编译包装器（mpicc 等）与 mpi.h 头文件，缺一不可
    pkgs.openmpi.dev
  ];
  versions.openmpi = pkgs.openmpi.version;
}
