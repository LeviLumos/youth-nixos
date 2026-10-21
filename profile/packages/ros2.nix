# ros2.nix —— ROS 2 模块：ROS 2 Humble 发行版最小环境 + colcon 构建工具。
# 特殊性：唯一使用 rosPkgs（nix-ros-overlay 自带的独立 nixpkgs 修订）的模块，
#   与主 pkgs 完全隔离，保证 ROS 用其官方测试过的依赖集。
# 被 default.nix 以 { inherit rosPkgs; } 引入；toolchain-checks.nix 的 ros2
#   检查会 colcon 实际构建一个最小 CMake 包。
# Keep ROS on its overlay's own nixpkgs revision and preserve its buildEnv.
{ rosPkgs }:
let
  ros = rosPkgs.rosPackages.humble;  # 固定 Humble 发行版
in
{
  packages = [
    rosPkgs.colcon  # colcon 来自 ROS overlay 的包集，与 ros 环境分开安装以便单独升级
    # 用 ROS 的 buildEnv 生成带环境变量（AMENT_PREFIX_PATH 等）的组合环境，
    # 使 ros2 CLI 与 source setup.bash 语义等价、开箱即用
    (ros.buildEnv {
      name = "ros2-humble-env";
      paths = with ros; [
        ros-base  # 最小可用的 ROS 核心（rclcpp 依赖其上）
        ament-cmake-core  # ament_cmake 构建体系核心
        python-cmake-module
      ];
    })
  ];
  # 版本元数据：distribution 记录发行版代号，写入 versions.json
  versions = {
    distribution = "humble";
    ros-base = ros.ros-base.version;
    colcon = rosPkgs.colcon.version;
  };
}
