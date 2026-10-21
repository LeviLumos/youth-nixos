# toolchain-checks.nix —— 工具链验收检查：对已打包的 dev-tools bundle 逐工具链
# 做“真实编译/运行”冒烟。
# 角色：被 profile/flake.nix 挂到 checks.x86_64-linux，nix flake check（或 nix
#   build 对应 check 派生）时执行；关键点是检查对象是 bundle 本身
#   （把 bundle/bin 置于 PATH 最前），而不是临时拼一个 shell，
#   确保装出来的东西真的可用。
# 消费方：scripts/koru/profile.sh 的 check 子命令构建本 flake 的包输出，
#   检查随 nix flake check 运行；任一检查失败即阻止新 profile 生成发布。
# Exercise the installed bundle, rather than an independently assembled shell.
{
  pkgs,
  bundle,
  versions,
}:
let
  # 通用检查封装：运行一段脚本，成功即产出 $out（touch $out 表示通过）
  check =
    name: script:
    pkgs.runCommand name { } ''
      # 强制使用 bundle 内的版本，避免拾取环境中的其他工具
      export PATH=${bundle}/bin:$PATH
      # 沙箱只读环境里给需要写 HOME 的工具一个临时可写目录
      export HOME=$TMPDIR/home
      mkdir -p "$HOME"
      ${script}
      touch $out
    '';
in
{
  # C/C++：验证 cc 指向 gcc_multi、Clang 版本匹配、64/32 位编译可执行、
  # LLVM IR 汇编/opt 校验管线、C++ 编译运行、clangd/clang-format 就位
  c-cpp = check "check-profile-c-cpp" ''
    # 确保 bundle 里的 cc 确实解析到 gcc_multi 的 cc（GCC 为默认编译器）
    test "$(readlink -f ${bundle}/bin/cc)" = "$(readlink -f ${pkgs.gcc_multi}/bin/cc)"
    clang --version | ${pkgs.gnugrep}/bin/grep -F '${versions.c-cpp-toolchain.clang}'
    cat > hello.c <<'C'
    int main(void) { return 0; }
    C
    gcc hello.c -o hello-gcc
    ./hello-gcc
    # 验证 multilib：能产出并运行 32 位 ELF
    gcc -m32 hello.c -o hello32
    # 确认产物确为 32 位
    ${pkgs.file}/bin/file hello32 | ${pkgs.gnugrep}/bin/grep -F 'ELF 32-bit'
    ./hello32
    clang hello.c -o hello-clang
    ./hello-clang
    # Clang → LLVM IR → bitcode → opt verify 的课程工具链管线
    clang -S -emit-llvm hello.c -o hello.ll
    llvm-as hello.ll -o hello.bc
    opt -passes=verify hello.bc -o verified.bc
    printf '%s\n' '#include <iostream>' 'int main() { std::cout << "ok"; }' > hello.cpp
    g++ hello.cpp -o hello-cpp
    test "$(./hello-cpp)" = ok
    clangd --version
    clang-format --version
  '';

  # Java：编译运行 Hello，运行时自检 feature 版本必须为 21
  java = check "check-profile-java" ''
    cat > Hello.java <<'JAVA'
    public class Hello {
      public static void main(String[] args) {
        if (Runtime.version().feature() != 21) throw new AssertionError();
        System.out.print("profile-java-ok");
      }
    }
    JAVA
    javac Hello.java
    test "$(java Hello)" = profile-java-ok
  '';

  # Node.js：主版本必须为 v22，npm 可用
  nodejs = check "check-profile-nodejs" ''
    node -e 'if (!process.version.startsWith("v22.")) process.exit(1)'
    npm --version
  '';

  # Python：uv/ruff 可用，ruff 能 lint+format，uv 建的 venv 里 Python 能跑脚本
  python = check "check-profile-python" ''
    uv --version
    ruff --version
    printf '%s\n' 'print("profile-python-ok")' > hello.py
    ruff check hello.py
    ruff format --check hello.py
    # 复用 nix 提供的解释器且禁止 uv 联网下载 Python，保证离线可复现
    uv venv --python ${pkgs.python3}/bin/python --no-python-downloads env
    test "$(env/bin/python hello.py)" = profile-python-ok
  '';

  # OpenMPI：编译 MPI 程序并双进程 Allreduce，结果正确才通过
  openmpi = check "check-profile-openmpi" ''
    cat > hello-mpi.c <<'C'
    #include <mpi.h>
    int main(int argc, char **argv) {
      int size, rank, sum;
      MPI_Init(&argc, &argv);
      MPI_Comm_size(MPI_COMM_WORLD, &size);
      MPI_Comm_rank(MPI_COMM_WORLD, &rank);
      MPI_Allreduce(&rank, &sum, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD);
      MPI_Finalize();
      return size == 2 && sum == 1 ? 0 : 1;
    }
    C
    mpicc hello-mpi.c -o hello-mpi
    # Nix's network sandbox has only loopback, which TCP BTL excludes by default.
    # https://docs.open-mpi.org/en/v5.0.2/tuning-apps/networking/tcp.html
    timeout 30 mpirun --oversubscribe -n 2 --mca pml ob1 --mca btl self,tcp \
      --mca btl_tcp_if_include lo ./hello-mpi
  '';

  # ROS 2：包列表含 ament_cmake/rclcpp，接口内省可用，
  # 并用 colcon 实际构建并运行一个最小 CMake 包
  ros2 = check "check-profile-ros2" ''
    ros2 pkg list > packages.txt
    ${pkgs.gnugrep}/bin/grep -Fx ament_cmake packages.txt
    ${pkgs.gnugrep}/bin/grep -Fx rclcpp packages.txt
    ros2 interface show std_msgs/msg/String
    mkdir -p src/profile_ros_smoke
    cat > src/profile_ros_smoke/package.xml <<'XML'
    <package format="3">
      <name>profile_ros_smoke</name><version>0.1.0</version>
      <description>Profile colcon build fixture</description>
      <maintainer email="fixture@example.invalid">Fixture</maintainer>
      <license>MIT</license><buildtool_depend>cmake</buildtool_depend>
      <export><build_type>cmake</build_type></export>
    </package>
    XML
    cat > src/profile_ros_smoke/CMakeLists.txt <<'CMAKE'
    cmake_minimum_required(VERSION 3.16)
    project(profile_ros_smoke C)
    add_executable(profile_ros_smoke main.c)
    install(TARGETS profile_ros_smoke DESTINATION bin)
    CMAKE
    printf '%s\n' 'int main(void) { return 0; }' > src/profile_ros_smoke/main.c
    colcon list --base-paths src
    colcon build --base-paths src --event-handlers console_direct+
    install/profile_ros_smoke/bin/profile_ros_smoke
  '';

  # 文档与构建工具：typst 能产出非空 PDF；just 能执行 justfile；
  # just 的 zsh 补全脚本存在且能被 zsh 加载
  document-and-build-tools = check "check-profile-document-build-tools" ''
    printf '%s\n' '= Profile test' 'Version-locked document compilation.' > document.typ
    typst compile document.typ document.pdf
    test -s document.pdf
    printf '%s\n' 'default:' '    printf profile-just-ok' > justfile
    just default > just-output.txt
    test "$(cat just-output.txt)" = profile-just-ok
    test -s ${bundle}/share/zsh/site-functions/_just
    ${pkgs.zsh}/bin/zsh -f -c '
      fpath=(${bundle}/share/zsh/site-functions $fpath)
      autoload -Uz _just
      autoload +X _just
      (( $+functions[_just] ))
    '
  '';
}
