include("src/models.jl")

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
    c[:object] = word
    push!(log_probs, Gen.assess(simple_stimulus_model, args, c)[1])
  end
  logsumexp(log_probs)
end


results = []
for (i,h) in enumerate(simple_human_data)
  model_args = (h[:loc], h[:verb1], h[:amt1_n], h[:verb2], haskey(h, :amt2_n) ? h[:amt2_n] : "NA", lowercase(h[:obj]))
  model_result = simple_model_unnormalized_posterior(model_args...) - simple_model_marginal(model_args[1:end-1]...)
  baseline_result = Gen.assess(baseline_simple, (h[:loc], h[:verb1], h[:amt1], h[:verb2], h[:amt2][1:end-1]), choicemap(:object => lowercase(h[:obj])))[1]
  push!(results, (h, model_result - baseline_result))
  println((i, h, model_result - baseline_result))
  println(length(filter(x -> x[end] > 0, results)))
  println(mean(map(x -> x[end], results)))
end
