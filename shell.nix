let
  pkgs = import (fetchTarball https://git.io/Jf0cc) {};
  newpkgs = import pkgs.path { overlays = [ (pkgsself: pkgssuper: {
    python37 = let
      packageOverrides = self: super: {
        # numpy = super.numpy_1_10;
      };
    in pkgssuper.python37.override {inherit packageOverrides;};
  } ) ]; };
  kernels = [
    # pkgs.python37Packages.ansible-kernel
    # pythonPackages.jupyter-c-kernel
    # pkgs.gophernotes
  ];
  additionalExtensions = [
    # "@jupyterlab/toc"
    # "@jupyterlab/fasta-extension"
    # "@jupyterlab/geojson-extension"
    # "@jupyterlab/katex-extension"
    # "@jupyterlab/mathjax3-extension"
    # "@jupyterlab/plotly-extension"
    # "@jupyterlab/vega2-extension"
    # "@jupyterlab/vega3-extension"
    # "@jupyterlab/xkcd-extension"
    # "jupyterlab-drawio"
    # "@jupyterlab/hub-extension"
    #jupyter labextension install @jupyter-widgets/jupyterlab-manager
    #jupyter labextension install @bokeh/jupyter_bokeh
    "@jupyter-widgets/jupyterlab-manager"
    "@bokeh/jupyter_bokeh"
    "@pyviz/jupyterlab_pyviz"
    # "jupyterlab_bokeh"
  ];
  pythonEnv = newpkgs.python37.withPackages (ps: with ps; [
    ipykernel
    python-language-server pyls-isort
    matplotlib numpy pandas
    autopep8
    gspread
    sqlalchemy
    flask
    flask_sqlalchemy
    flask_assets
    flask-restful
    flask_marshmallow
    marshmallow-sqlalchemy
  ]);

  frontendEnv = [
    pkgs.elmPackages.elm
    pkgs.elmPackages.elm-format
    pkgs.elmPackages.elm-live
    pkgs.elmPackages.elm-test
  ];

in newpkgs.mkShell rec {
  buildInputs = [
    pythonEnv
    pkgs.nodejs
    frontendEnv
    # newpkgs.tectonic # not good
    # newpkgs.python-language-server
    # newpkgs.pyls-isort
  ] ++ kernels;
}
