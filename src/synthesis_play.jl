# This file is just a "scratch pad" that Cathy and I were using to play with
# synthesis prompts.

# "MASS", "LENGTH", "CURRENCY", "DURATION", "VOLUME", "PRESSURE",
# "AREA", "SPEED", "TEMPERATURE", "TIME", "DATA_RATE", "FREQUENCY", "VOLTAGE",
# "RESISTANCE", or "POWER".
include("language_distributions.jl")

# Where are we going to get the general categories of noun?
concrete_noun_categories = ["room", "store", "tool", "food", "clothing", "animal",
                            "job", "appliance", "building", "place", "country", "thing",
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
mutable struct RootNounNode <: Node
    category :: String
    verb :: String
    observed_val :: Union{String, Nothing}
end

mutable struct InternalNounNode <: Node
    category :: String
    verb :: String
    preposition :: String
    parent :: Node
    observed_val :: Union{String, Nothing}
end

concrete_noun_categories = ["room", "store", "tool", "food", "clothing", "animal",
                            "job", "appliance", "building", "place", "country", "thing",
                            "plant", "object", "vehicle"]

fill_nth_blank("An example of a place is a [?], [?], or [?].", 1)


@dist uniform_from_list(l) = l[uniform_discrete(1, length(l))]

@gen function observe_value_root(root)
    # Generic prompt that gets examples for any parent category.
    article = in(root.category[1], ["a", "e", "i", "o", "u"]) ? "an" : "a"
    observed_category ~ fill_blank("I $(root.verb) $article $(root.category) yesterday, in particular I $(root.verb) a [?], which is an example of $article $(root.category).")
    return observed_category
end

@gen function generate_root_noun_node()
    category ~ uniform_from_list(concrete_noun_categories)
    article = in(category[1], ["a", "e", "i", "o", "u"]) ? "an" : "a"
    verb ~ fill_blank("I [?] $article $category yesterday.")
    root_node = RootNounNode(category, verb, nothing)
    
    # Choose whether to observe.
    observe_root ~ bernoulli(0.5)
    observed_val = observe_root ? {:observed_val} ~ observe_value_root(root_node) : nothing
    root_node.observed_val = observed_val
    return root_node
end
generate_root_noun_node()

# TODO: sharpen distribution

@gen function observe_value_child(child, parent)
    # Generic prompt that gets examples for any parent category.
    article = in(root.category[1], ["a", "e", "i", "o", "u"]) ? "an" : "a"
    observed_category ~ fill_blank("I $(root.verb) $article $(root.category) yesterday, in particular I $(root.verb) a [?], which is an example of $article $(root.category).")
    return observed_category
end

root1 = RootNounNode("store", "visited", "grocery")
root_val = root1.observed_val == nothing ? root1.category : root1.observed_val

@gen function generate_child_noun_node(parent)
    parent_value = parent.observed_val == nothing ? parent.category : parent.observed_val
    
    best_prepositions = filter(x -> in(x, prepositions), top_words_xl("I [?] a [?] [?] the $(parent_value) yesterday.", 3))[1:4]
    preposition ~ fill_nth_blank_from_list("I [?] a [?] [?] the $(parent_value) yesterday.", best_prepositions, 3)
    verb ~ fill_nth_blank("$(titlecase(preposition)) the $(parent_value), I [?] a [?] yesterday.", 1)
    category ~ fill_nth_blank_from_list("I $verb this [?] $preposition the $(parent_value) yesterday.", concrete_noun_categories, 1)
    return verb, category, preposition
end

# Unobserved parent.
generate_child_noun_node(RootNounNode("store", "visited", nothing))

# Observed parent.
generate_child_noun_node(RootNounNode("store", "visited", "grocery"))


filter(x -> in(x, prepositions), top_words_xl("I [?] a thing [?] the room yesterday.", 3))[1:4]


filter(x -> in(x, prepositions), top_words_xl("I [?] a store [?] the country yesterday.", 2))[1:4]
