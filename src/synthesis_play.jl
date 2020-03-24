# This file is just a "scratch pad" that Cathy and I were using to play with
# synthesis prompts.

# "MASS", "LENGTH", "CURRENCY", "DURATION", "VOLUME", "PRESSURE",
# "AREA", "SPEED", "TEMPERATURE", "TIME", "DATA_RATE", "FREQUENCY", "VOLTAGE",
# "RESISTANCE", or "POWER".
include("language_distributions.jl")

# Where are we going to get the general categories of noun?
concrete_noun_categories = ["room", "store", "tool", "food", "clothing", "animal",
                            "job", "appliance", "building", "place", "country",
                            "plant", "vehicle"]
abstract_noun_categories = ["emotion", "subject", "thing", "object"]

prepositions = ["of", "with", "at", "from", "into", "during", "including", "until", "against", "among", "throughout", "despite", "towards", "upon", "to", "in", "for", "on", "by", "about", "like", "through", "over", "before", "between", "after", "since", "without", "under", "within", "along", "following", "across", "behind", "behind", "beyond", "plus", "except", "but", "up", "out", "around", "down", "off", "above", "near"]

# Generating a concrete noun
# With no parent, just pick at
# random:
nodes = []
push!(nodes, concrete_noun_categories[uniform_discrete(1, length(concrete_noun_categories))])

@dist uniform_from_list(l) = l[uniform_discrete(1, length(l))]

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

function fill_two_blanks(prompt)
    word1 = fill_nth_blank(prompt, 2)
    println(reverse(replace(reverse(prompt), "]?[" => reverse(word1), count=1)))
    fill_blank(reverse(replace(reverse(prompt), "]?[" => reverse(word1), count=1))), word1
end

function fill_two_blanks_forward(prompt)
    word1 = fill_nth_blank(prompt, 1)
    word1, fill_blank(replace((prompt), "[?]" => (word1), count=1))
end


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

function get_article(noun)
    return in(string(noun[1]), ["a", "e", "i", "o", "u"]) ? "an" : "a"
end

function render_text(node, verbose=true)
    # Renders text as we go based on the parent.
    article = get_article(node.category)
    text = "I $(node.verb) $article $(node.category)"

    if typeof(node) == InternalNounNode
        parent_noun = node.parent.observed_val == nothing ? node.parent.category : node.parent.observed_val
        text = "$text $(node.preposition) that $parent_noun"
    end
    if (node.observed_val != nothing)
        text = "$text. It was $(get_article(node.observed_val)) $(node.observed_val)."
    end
    if verbose println(text) end
    return text
end 
root = generate_root_noun_node(true)
render_text(root)
child = generate_child_noun_node(root)
render_text(child)

@gen function observe_value_root(root)
    # Generates root noun node observation using the category and verb. 
    article = get_article(root.category)
    observed_category ~ fill_blank("I $(root.verb) $article $(root.category) yesterday, in particular I $(root.verb) a [?], which is an example of $article $(root.category).")
    return observed_category
end

@gen function observe_value_root_category_specific(root)
    # TODO: consider disallowing the category name itself
    article = get_article(root.category)
    base_prompt = "I $(root.verb) $article $(root.category)."
    if root.category == "store"
        prompt = "$base_prompt Specifically, I $(root.verb) a [?] store." 
        observed_category ~ fill_blank(prompt)
        observed_category_text = "$observed_category store"
    elseif root.category == "room"
        prompt = "$base_prompt Specifically, I $(root.verb) the [?] in my house."
    elseif root.category == "tool"
        
    end
    return observed_category, observed_category_text
end
observe_value_root_category_specific(RootNounNode("store", "visited", nothing))
prompt = "An example of a specific kind of room is a [?]room"
prompt = "A specfic example of a store is a [?] store"
println(top_words_xl("I entered a room. Specifically, I entered a [?].", 1)[1:15])
fill_nth_blank("I got a room. Specifically, I got the [?]", 1)
concrete_noun_categories = ["room", "store", "tool", "food", "clothing", "animal",
                            "job", "appliance", "building", "place", "country", "thing",


@gen function generate_root_noun_node(verbose=true, use_category=nothing, use_observe=nothing)
    category = use_category == nothing ? {:category} ~ uniform_from_list(concrete_noun_categories) : use_category
    article = get_article(category)
    verb ~ fill_blank("I [?] a specific $category yesterday.")
    root_node = RootNounNode(category, verb, nothing)
    
    # Choose whether to observe.
    observe_root = use_observe == nothing ? {:observe_root} ~ bernoulli(0.5) :  use_observe 
    observed_val = observe_root ? {:observed_val} ~ observe_value_root(root_node) : nothing
    root_node.observed_val = observed_val
    render_text(root_node, verbose)
    return root_node
end

for category in concrete_noun_categories
    println("Demoing root category: $category")
    for i in 1:15
        generate_root_noun_node(true, category, false)
    end
end


# TODO: sharpen distribution

@gen function observe_value_child(child, parent)
    # Generic prompt that gets examples for any parent category.
    article = in(root.category[1], ["a", "e", "i", "o", "u"]) ? "an" : "a"
    observed_category ~ fill_blank("I $(root.verb) $article $(root.category) yesterday, in particular I $(root.verb) a [?], which is an example of $article $(root.category).")
    return observed_category
end

root1 = RootNounNode("store", "visited", "grocery")
root_val = root1.observed_val == nothing ? root1.category : root1.observed_val

@gen function generate_child_noun_node(parent, verbose=true)
    parent_value = parent.observed_val == nothing ? parent.category : parent.observed_val
    
    best_prepositions = filter(x -> in(x, prepositions), top_words_xl("I [?] a [?] [?] the $(parent_value) yesterday.", 3))[1:4]
    preposition ~ fill_nth_blank_from_list("I [?] a [?] [?] the $(parent_value) yesterday.", best_prepositions, 3)
    verb ~ fill_nth_blank("$(titlecase(preposition)) the $(parent_value), I [?] a [?] yesterday.", 1)
    category ~ fill_nth_blank_from_list("I $verb this [?] $preposition the $(parent_value) yesterday.", concrete_noun_categories, 1)
    
    node = InternalNounNode(category, verb, preposition, parent, nothing)
    render_text(node, verbose)
    return node
end
generate_child_noun_node(generate_root_noun_node(true))

# Unobserved parent.
generate_child_noun_node(RootNounNode("store", "visited", nothing))

# Observed parent.
generate_child_noun_node(RootNounNode("store", "visited", "grocery"))


# Try building a tree.
root = generate_root_noun_node()


filter(x -> in(x, prepositions), top_words_xl("I [?] a thing [?] the room yesterday.", 3))[1:4]


filter(x -> in(x, prepositions), top_words_xl("I [?] a store [?] the country yesterday.", 2))[1:4]
