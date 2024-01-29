{  pkgs, lib, config, specialArgs, ... }:
let

  nixGLMesaWrap = pkg:
    pkgs.runCommand "${pkg.name}-nixgl-wrapper" { } ''
      mkdir $out
      ln -s ${pkg}/* $out
      rm $out/bin
      mkdir $out/bin
      for bin in ${pkg}/bin/*; do
       wrapped_bin=$out/bin/$(basename $bin)
       echo "exec ${lib.getExe pkgs.nixgl.nixGLIntel} $bin \$@" > $wrapped_bin
       chmod +x $wrapped_bin
      done
    '';

  nixGLVulkanWrap = pkg:
    pkgs.runCommand "${pkg.name}-nixgl-wrapper" { } ''
      mkdir $out
      ln -s ${pkg}/* $out
      rm $out/bin
      mkdir $out/bin
      for bin in ${pkg}/bin/*; do
       wrapped_bin=$out/bin/$(basename $bin)
       echo "exec ${
         lib.getExe pkgs.nixgl.nixVulkanIntel
       } $bin \$@" > $wrapped_bin
       chmod +x $wrapped_bin
      done
    '';

  nixGLVulkanMesaWrap = pkg:
    pkgs.runCommand "${pkg.name}-nixgl-wrapper" { } ''
      mkdir $out
      ln -s ${pkg}/* $out
      rm $out/bin
      mkdir $out/bin
      for bin in ${pkg}/bin/*; do
       wrapped_bin=$out/bin/$(basename $bin)
       echo "${lib.getExe pkgs.nixgl.nixGLIntel} ${
         lib.getExe pkgs.nixgl.nixVulkanIntel
       } $bin \$@" > $wrapped_bin
       chmod +x $wrapped_bin
      done
    '';

  # linkAppConfig = appConfig: {
  #   home.file.".config/${appConfig}" = {
  #       source = config.lib.file.mkOutOfStoreSymlink "${specialArgs.path_to_dotfiles}/.config/${appConfig}";
  #       recursive = true;
  #   };
  # };


  linkAppConfig = appName: directory: lib.hm.dag.entryAfter ["writeBoundary"]''
    rm -rf "${specialArgs.home}/${directory}/${appName}"
    ln -s "${specialArgs.path_to_dotfiles}/${directory}/${appName}" "${specialArgs.home}/${directory}/${appName}"
  '';

  defaultLinkAppConfig = appName: linkAppConfig appName ".config";

in {
  nixGLMesaWrap = nixGLMesaWrap;
  nixGLVulkanWrap = nixGLVulkanWrap;
  nixGLVulkanMesaWrap = nixGLVulkanMesaWrap;
  linkAppConfig = defaultLinkAppConfig;
}
