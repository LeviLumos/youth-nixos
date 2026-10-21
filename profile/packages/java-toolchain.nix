# java-toolchain.nix —— Java 工具链模块：JDK 21（LTS）。
# 被 default.nix 引入；toolchain-checks.nix 的 java 检查会在运行时校验
#   Runtime.version().feature() == 21，与此处编译期断言双重保险。
{ pkgs }:
# 编译期断言：主版本必须是 21，防止 nixpkgs 换代后静默漂移
assert pkgs.lib.assertMsg (
  pkgs.lib.versions.major pkgs.jdk21.version == "21"  # JDK 自带 javac/java/jshell 等，无需额外包
) "The Java profile requires JDK 21";
{
  packages = [ pkgs.jdk21 ];
  versions.jdk = pkgs.jdk21.version;
}
