{ pkgs, ... }:
{
  # Azure DevOps tooling, for the Skadii work-item backlog at
  # dev.azure.com/SKADII.
  #
  # The `azure-devops` extension is baked in via withExtensions rather than
  # installed at runtime with `az extension add`. That command writes into
  # ~/.azure/cliextensions and pulls a wheel from the network, which would
  # survive rebuilds only by accident — this way the extension is part of the
  # derivation and comes back on any machine that builds this flake.
  #
  # Auth is `az login` (Entra ID), deliberately not a PAT: no secret lands on
  # disk, refresh is az's problem, and the same session authenticates both this
  # CLI and the Azure DevOps MCP server (see ~/workspace/skadii/.mcp.json).
  home.packages = [
    (pkgs.azure-cli.withExtensions [ pkgs.azure-cli-extensions.azure-devops ])
  ];
}
