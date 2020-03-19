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

word_probs_xl("I bought a thing [?] the store.")

function fill_two_blanks(prompt)
    word1 = fill_nth_blank(prompt, 2)
    println(reverse(replace(reverse(prompt), "]?[" => reverse(word1), count=1)))
    fill_blank(reverse(replace(reverse(prompt), "]?[" => reverse(word1), count=1))), word1
end

function fill_two_blanks_forward(prompt)
    word1 = fill_nth_blank(prompt, 1)
    word1, fill_blank(replace((prompt), "[?]" => (word1), count=1))
end


fill_two_blanks("I [?] a [?] [?] the store.")

concrete_noun_categories[sortperm(word_probs_xl("I visited a [?] in a vehicle.", concrete_noun_categories, 1))[end-3]]

top_words_xl("In the place, I [?] a [?] yesterday.", 1)



abstract type Node end
struct RootNounNode <: Node
    category :: String
    verb :: String
end

struct InternalNounNode <: Node
    category :: String
    verb :: String
    preposition :: String
    parent :: Node
end

@dist uniform_from_list(l) = l[uniform_discrete(1, length(l))]
@gen function generate_root_noun_node()
    category ~ uniform_from_list(concrete_noun_categories)
    article = in(category[1], ["a", "e", "i", "o", "u"]) ? "an" : "a"
    verb ~ fill_blank("I [?] $article $category yesterday.")
    # RootNounNode(category, verb)
    category, verb
end

top_words_xl("Using the tool, I [?] the [?] yesterday.", 1)

top_words_xl("I [?] a [?] [?] the store yesterday.", 3)

# TODO: sharpen distribution

@gen function generate_child_noun_node(parent)
    best_prepositions = filter(x -> in(x, prepositions), top_words_xl("I [?] a store [?] the $(parent.category) yesterday.", 2))[1:4]
    preposition ~ fill_nth_blank_from_list("I [?] a store [?] the $(parent.category) yesterday.", best_prepositions, 2)
    verb ~ fill_nth_blank("$(titlecase(preposition)) the $(parent.category), I [?] a store yesterday.", 1)
    best_categories = filter(x -> in(x, concrete_noun_categories),
                            top_words_xl("I [?] this [?] [?] the $(parent.category) yesterday."))[1:6]
    category ~ fill_nth_blank_from_list("I $verb this [?] $preposition the $(parent.category) yesterday.", best_categories, 1)
    return verb, category, preposition
end

filter(x -> in(x, prepositions), top_words_xl("I [?] a thing [?] the room yesterday.", 3))[1:4]
generate_child_noun_node(RootNounNode("country", "visited"))

filter(x -> in(x, prepositions), top_words_xl("I [?] a store [?] the country yesterday.", 2))[1:4]
