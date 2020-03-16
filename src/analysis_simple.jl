using Statistics: mean
include("models.jl")

raw_roth_data = load_extracted_raw_data("roth_dataset/raw/CURRENCY-MASS-2020-03-13T19:01:05.083.dat")
associated_quantity_set_raw_data!(raw_roth_data)
associated_quantity_initialize_processed_data!()

# Processing human data
using SQLite
using CSV
db = SQLite.DB()

function human_trial_as_dictionary(human_datum)
  h = Dict()
  h[:loc] = human_datum[1]
  h[:verb1] = human_datum[2]
  h[:amt1] = human_datum[3]
  h[:verb2] = human_datum[4]
  h[:amt2] = human_datum[5]
  h[:obj] = lowercase(human_datum[6])
  for (v, read, write) in [(:verb1, :amt1, :amt1_n), (:verb2, :amt2, :amt2_n)]
    if h[v] == "costs"
      h[write] = parse(Float64, h[read][2:end])
    elseif h[v] == "weighs"
      h[write] = parse(Float64, split(h[read], " ")[1]) * 453.592 # grams per pound
    end
  end
  h
end

# Load human results
const human_data_file = "data/pilot-amworld-2/amworld-trials-2.csv"
tbl = CSV.File(human_data_file) |> SQLite.load!(db, "results")
simple_human_data = [human_trial_as_dictionary([r[i] for i=1:6]) for r in
                     DBInterface.execute(db, "SELECT location, verb_0, amount_0, verb_1, amount_1, object_0
                                              FROM results WHERE trial_type = 'simple' AND object_0 != 'NA'")]

# Analyze human results
function simple_model_unnormalized_posterior(location, verb1, amt1, verb2, amt2, obj)
  # Model arguments
  args = (location, in("costs", [verb1, verb2]), in("weighs", [verb1, verb2]))

  # Model observations
  c = choicemap(:item => obj)
  c[verb1 == "costs" ?  :price : :mass] = amt1
  if verb2 != "NA"
    c[verb2 == "costs" ? :price : :mass] = amt2
  end

  # Model score
  joint_pdf, = Gen.assess(simple_stimulus_model, args, c)
  joint_pdf
end

function simple_model_marginal(location, verb1, amt1, verb2, amt2, n=1000)
  args = (location, in("costs", [verb1, verb2]), in("weighs", [verb1, verb2]))

  c = choicemap()
  c[verb1 == "costs" ?  :price : :mass] = amt1
  if verb2 != "NA"
    c[verb2 == "costs" ? :price : :mass] = amt2
  end

  # Now try every object in the top N for this location.
  log_probs = Float64[]
  for (i,word) in enumerate(top_words_xl("The $location has many objects in it, for example the [?].")[1:n])
    c[:item] = word
    push!(log_probs, Gen.assess(simple_stimulus_model, args, c)[1])
  end
  logsumexp(log_probs)
end

function simple_model_posterior(location, verb1, amt1, verb2, amt2, obj, n=1000)
  simple_model_unnormalized_posterior(location, verb1, amt1, verb2, amt2, obj) -
  simple_model_marginal(location, verb1, amt1, verb2, amt2, n)
end

# We need to filter human data that is out of vocabulary.
simple_human_data = filter(x -> in(x[:obj], xlvocab), simple_human_data)
results = []
for (i,h) in enumerate(simple_human_data)
  # Compute model posterior probability
  model_args = (h[:loc], h[:verb1], h[:amt1_n], h[:verb2], haskey(h, :amt2_n) ? h[:amt2_n] : "NA", lowercase(h[:obj]))
  model_posterior = simple_model_posterior(model_args...)
  if isnan(model_posterior)
    error("$h posterior is nan!")
  end

  # Compute baseline posterior probability
  baseline_model_args = (h[:loc], h[:verb1], h[:amt1], h[:verb2], h[:amt2][1:end-1])
  baseline_result = Gen.assess(simple_stimulus_baseline, baseline_model_args, choicemap(:item => lowercase(h[:obj])))[1]

  # Push log ratio onto results.
  push!(results, (h, model_posterior - baseline_result))

  print("$i\t$(h[:loc]), $(h[:verb1]) $(h[:amt1]), $(h[:verb2]) $(h[:amt2]), $(h[:obj])")
  println("\t$(model_posterior - baseline_result)")

#  println(length(filter(x -> x[end] > 0, results)))
#  println(mean(map(x -> x[end], results)))
end
