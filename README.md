# amazon-world

To use the Julia code:

* Install Julia
* Create a Python virtual environment in this directory, and activate it.
* Install `torch` and `transformers` (e.g., via `pip`, using `pip install torch`
  and `pip install transformers`) within the virtual environment.
* Start Julia, with the project set to the current directory, and  with the
  `PYTHON` environment variable set: (`PYTHON=$(which python) JULIA_PROJECT=. julia`).
  Inside the Julia shell, run `using Pkg; Pkg.build("PyCall")`.
