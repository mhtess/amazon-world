using Gen

include("language_models.py")
include("associated_quantity.jl")

@gen function simple_stimulus_baseline(location, observe_price, observe_weight)
  {:item} ~ fill_blank("There are many objects in the $location, for example the [?].")
end

@gen function simple_stimulus_model(location, observe_price, observe_weight)
  item ~ fill_blank("There are many objects in the $location, for example the [?].")
  price = observe_price  ? {:price} ~ associated_quantity(lowercase(item), "CURRENCY") : nothing
  mass  = observe_weight ? {:mass}  ~ associated_quantity(lowercase(item), "MASS")     : nothing
  item, price, mass
end

@gen function complex_stimulus(same_store, n_0, n_1, objects_0, objects_1)
  objects_0 = copy(objects_0)
  objects_1 = copy(objects_1)

  store_0 ~ fill_blank("I went to the [?] store down the block.")
  store_1 = store_0
  if !same_store
    store_1 ~ fill_blank("I went to the [?] store down the block.")
  end

  # Buy Pat's objects
  i = 1
  while length(objects_0) < n_pat
    prompt = "I bought $n_0 things at the $store_0 store, including this [?]"
    if length(objects_0) > 0
      prompt = "$prompt and this $(join(objects_0, " and this "))"
    end
    prompt = "$prompt."
    push!(objects_0, {:pat => i} ~ fill_blank(prompt))
    i += 1
  end

  # Buy Sam's objects
  i = 1
  while length(objects_1) < n_1
    prompt = "I bought $n_1 things at the $store_1 store, including this [?]"
    if length(objects_1) > 0
      prompt = "$prompt and this $(join(objects_1, " and this "))"
    end
    prompt = "$prompt."
    push!(objects_1, {:sam => i} ~ fill_blank(prompt))
    i += 1
  end

  (store_0, objects_0, {:pat_total} ~ associated_quantities_sum(objects_0, "CURRENCY"),
   store_1, objects_1, {:sam_total} ~ associated_quantities_sum(objects_1, "CURRENCY"))
end

# GPT-2 Complex Baseline
function complex_baseline_score(h)
  # I went to a store today, the ____ store, where I spent $d on the following
  # n items: ____, ____, ____, and ____. My friend went to [the same store | a different store, the ____ store], and
  # spent $d on n items: ____, ____, ____, and ____.
  prompt = [(false, "I went to a store today, in particular it was the "), (true, h[:pat_store]), (false, "store, where I spent \$$(h[:pat_price]) on the following $(h[:n_pat]) items:")]
  if length(h[:pat_objects_initial]) > 0
    push!(prompt, (false, "this $(join(h[:pat_objects_initial], ", this ")),"))
  end
  for obj in h[:pat_objects_inferred][1:end-1]
    push!(prompt, (false, "this"))
    push!(prompt, (true, obj))
    push!(prompt, (false, ","))
  end
  for obj in h[:pat_objects_inferred][end:end]
    push!(prompt, (false, h[:n_pat] == 1 ? "this" : "and this"))
    push!(prompt, (true, obj))
  end
  push!(prompt, (false, ". My friend went to $(h[:is_same] ? "the same store" : "a different store, the")"))
  if !h[:is_same]
    push!(prompt, (true, h[:sam_store]))
    push!(prompt, (false, "store"))
  end
  push!(prompt, (false, ", and spent \$$(h[:sam_price]) on the following $(h[:n_sam]) items:"))
  if length(h[:sam_objects_initial]) > 0
    push!(prompt, (false, "this $(join(h[:sam_objects_initial], ", this ")),"))
  end
  for obj in h[:sam_objects_inferred][1:end-1]
    push!(prompt, (false, "this "))
    push!(prompt, (true, obj))
    push!(prompt, (false, ","))
  end
  for obj in h[:sam_objects_inferred][end:end]
    push!(prompt, (false, h[:n_sam] == 1 ? "this" : "and this"))
    push!(prompt, (true, obj))
  end
  gpt2_score_text_pieces(prompt)
end
