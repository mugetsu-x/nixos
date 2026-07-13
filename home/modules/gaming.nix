{ pkgs, ... }: {
  # FPS / frametime / temp overlay. Steam launch option:
  #   mangohud %command%
  programs.mangohud.enable = true;

  home.packages = with pkgs; [
    # Check the NVIDIA + 32-bit stack is actually wired up:
    #   vulkaninfo --summary
    vulkan-tools
  ];
}
