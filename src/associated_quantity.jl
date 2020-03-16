using CSV, Dates, Serialization

######################
# Data Preprocessing #
######################

const roth_raw_data_file = "roth_dataset/raw/noun_obj_quantization.csv"
const roth_raw_serialization_path = "roth_dataset/raw/"

"""
  download_roth_data_if_missing()

Download the Roth 'distributions over quantities' raw data from the Internet if
it is not available locally.
"""
function download_roth_data_if_missing()
  url = "https://storage.googleapis.com/measures-grounding/DoQ/raw/nouns/noun_obj_quantization.csv"
  if !isfile(roth_raw_data_file)
    println("Downloading Roth data (7 GB) to $roth_raw_data_file.")
    download(url, roth_raw_data_file)
  else
    println("Roth data already downloaded; using cached CSV at $roth_raw_data_file.")
  end
end

"""
  last_word(str)
Extract the last word from a string.
"""
last_word(str) = lowercase(split(str)[end])

"""
  process_raw_roth_data(quantity_types :: Vector{String},
                        extract_word = last_word,
                        words = nothing)

Process the raw Roth dataset and return `results`, a value of type
Dict{String, Dict{String, Vector{Float64}}}`, mapping each `quantity_type` in
`quantity_types` to a dictionary which itself maps words to vectors of associated
quantities. The `quantity_types` argument represents a subset of the following
types of quantity: "MASS", "LENGTH", "CURRENCY", "DURATION", "VOLUME", "PRESSURE",
"AREA", "SPEED", "TEMPERATURE", "TIME", "DATA_RATE", "FREQUENCY", "VOLTAGE",
"RESISTANCE", or "POWER".

Each entry in the Roth dataset is associated with a string. The `extract_word`
function normalizes that string; entries that normalize to the same string will
be combined in the results. By default, we extract the last word of the string.

Finally, the `words` argument can be used to limit the extraction to a fixed set
of normalized words, which will become the keys of the returned dictionary.
"""
function extract_raw_quantities(quantity_types, extract_word = last_word, words = nothing)

  # Helper function to read the numbers stored in the Roth file.
  function extract_numbers(row)
    components = map(x -> split(x, ':'), split(row[end][2:end-3], ", "))
    collect(Base.Iterators.flatten(map(x -> collect(range(parse(Float64, x[1][3:end]),
                                      (let upper = parse(Float64, x[2][1:end-2]);
                                        isinf(upper) ?
                                          parse(Float64, x[1][3:end]) :
                                          upper;
                                       end),
                                      length=2+Int(parse(Float64, x[3]))))[2:end-1],
                                      components)))
  end

  download_roth_data_if_missing()

  # Open data file
  noun_data = CSV.File(roth_raw_data_file)

  # Initialize results
  results = Dict([t => Dict{String, Vector{Float64}}() for t in quantity_types]...)

  # Process each row
  for (i, row) in enumerate(noun_data)
    if i % 100000 == 0
      println("Loading Roth data, row $i")
    end

    noun_phrase, _, quant_type, quantities = row
    word = extract_word(noun_phrase)
    if !haskey(results, quant_type) ||  !isnothing(words) && !in(words, word)
      continue
    end

    if haskey(results[quant_type], word)
      append!(results[quant_type][word], extract_numbers(row))
    else
      results[quant_type][word] = extract_numbers(row)
    end
  end

  # Serialize results
  serialization_filename = "$(join(quantity_types, "-"))-$(now())"
  open("$(roth_raw_serialization_path)/$(serialization_filename).dat", "w") do f
    serialize(f, results)
  end

  return results
end

function load_extracted_raw_data(result_file)
  open(result_file) do f
    deserialize(f)
  end
end

#######################
# Associated Quantity #
#######################

using Gen
using Statistics: median

raw_results = nothing
distribution_parameters = Dict()

function associated_quantity_set_raw_data!(rawdata)
  global raw_results = rawdata
end

function associated_quantity_initialize_processed_data!()
  for k in keys(raw_results)
    distribution_parameters[k] = Dict()
  end
end

function associated_quantity_load_processed_data(processed_data_file)
  open(processed_data_file, "w") do f
    serialize(f, distribution_parameters)
  end
end

function associated_quantity_save_processed_data(processed_data_file)
  global distribution_parameters = open(processed_data_file) do f
    deserialize(f)
  end
end

function associated_quantity_log_median(item, type)
  if !haskey(distribution_parameters[type], item)
    if !haskey(raw_results[type], item)
      return -10.0
    end
    distribution_parameters[type][item] = median(log.(raw_results[type][item]))
  end
  distribution_parameters[type][item]
end

@dist associated_quantity(item, type) =
    exp(normal(associated_quantity_log_median(item, type), 1.0))


########################
#   Sum of Quantities  #
########################
associated_quantities_total_log_median(items, type) =
  logsumexp([associated_quantity_log_mean(item, type) for item in items])
@dist associated_quantities_sum(items, type) =
  exp(normal(associated_quantities_total_log_median(items, type), 1.0))
