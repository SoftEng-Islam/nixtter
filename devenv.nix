{ pkgs, ... }: {
  env.GREET = "Hello";
  packages = with pkgs; [ jq ];
  enterShell = ''
    echo $GREET
    jq --version
  '';
}
