# amazon-world

To use the Julia code:

* Install Julia
* Create a Python virtual environment in this directory, and activate it.
* Install dependencies from `requirements.txt` within the virtualenv (`pip install -r requirements.txt`)
* Clone this repository:  https://github.com/huggingface/transformers
* Inside of the `transformers` directory, modify `setup.py` so that it
  relies on "tokenizers == 0.6.0" instead of "0.5.2". (Line 93 of the file.)
* Run `pip install .` inside the transformers directory (with your virtualenv activated).
* Start Julia, with the project set to the current directory, and  with the
  `PYTHON` environment variable set: (`PYTHON=$(which python) JULIA_PROJECT=. julia`).
  Inside the Julia shell, run `using Pkg; Pkg.build("PyCall")`.
