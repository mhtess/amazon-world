# This file is just a "scratch pad" that Cathy and I were using to play with
# synthesis prompts.


# "MASS", "LENGTH", "CURRENCY", "DURATION", "VOLUME", "PRESSURE",
# "AREA", "SPEED", "TEMPERATURE", "TIME", "DATA_RATE", "FREQUENCY", "VOLTAGE",
# "RESISTANCE", or "POWER".
include("language_distributions.jl")

# Where are we going to get the general categories of noun?
concrete_noun_categories = ["room", "store", "tool", "food", "clothing", "animal",
                            "job", "device", "building", "place", "country", "thing",
                            "plant", "object", "vehicle"]
abstract_noun_categories = ["emotion", "subject"]

# Generating a concrete noun
# With no parent, just pick at
# random:
nodes = []
push!(nodes, concrete_noun_categories[uniform_discrete(1, length(concrete_noun_categories))])

println(top_words_xl("An example of a clothing is a [?].")[1:50])

function print_until(prob, prompt)
    top_words = reverse(sort(collect(zip(xlvocab, word_probs_xl(prompt))), by = x -> x[2]))
    total = 0
    i = 1
    while total < prob
        println(top_words[i])
        total += top_words[i][2]
        i += 1
    end

    println("There are $i things.")
end


exp(logpdf(fill_blank, "shirt", "An example of a clothing is [?]."))

print_until(0.8, "An example of a thing is a [?].")

print_until(0.8, "An example of a clothing is a [?].")

prepositions = ["of", "with", "at", "from", "into", "during", "including", "until", "against", "among", "throughout", "despite", "towards", "upon", "to", "in", "for", "on", "by", "about", "like", "through", "over", "before", "between", "after", "since", "without", "under", "within", "along", "following", "across", "behind", "behind", "beyond", "plus", "except", "but", "up", "out", "around", "down", "off", "above", "near"]
println(sort(collect(zip(prepositions, (word_probs_xl("I [?] in the store.", prepositions)))), by=x -> -x[2]))

word_probs_xl("I bought a [?] at the store.", concrete_noun_categories)
