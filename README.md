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

To see if you can access the `transformers` library within Julia:
  ```
  using PyCall
  transformers = pyimport("transformers")
  ```

The lines at the top of the `simple_analysis.jl` file are:
```
raw_roth_data = load_extracted_raw_data("roth_dataset/raw/CURRENCY-MASS-2020-03-16T17:21:03.439.dat")
associated_quantity_set_raw_data!(raw_roth_data)
associated_quantity_initialize_processed_data!()
```
These load a small version of the Roth data for use. The data only include the words
from the XL vocabulary, and only include currency and mass. To create a different `.dat`
file to read from, use `extract_raw_quantities`, which will download the full 7GB Roth
data, but then extract whatever you find useful (see docstring).


You can then do

```
include("models.jl")
```
This should make many functions available to you:

- associated_quantity: takes as input a word and a "quantity type" (e.g. "MASS" and "CURRENCY") and samples a plausible weight/price
- fill_blank: takes a prompt with a hole ([?]) and samples a word to fill it in. Optionally takes a second argument, a list of possible words to limit the results to
- top_words_xl: given a prompt, return a sorted list of most probable words to fill in the hole
- word_probs_xl: takes in a prompt and a list of words, and returns a list of probabilities, one for each word (by default, the list of words is the whole vocabulary)
- elaborate: use GPT-2 to elaborate on a prompt (no holes)

You can see these functions being used from within Gen in the models.jl file.
