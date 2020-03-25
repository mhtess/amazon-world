# This file is just a "scratch pad" that Cathy and I were using to play with
# synthesis prompts.

# "MASS", "LENGTH", "CURRENCY", "DURATION", "VOLUME", "PRESSURE",
# "AREA", "SPEED", "TEMPERATURE", "TIME", "DATA_RATE", "FREQUENCY", "VOLTAGE",
# "RESISTANCE", or "POWER".
include("language_distributions.jl")

# Where are we going to get the general categories of noun?
concrete_noun_categories = ["room", "store", "tool", "food", "clothing", "animal",
                            "job", "appliance", "building", "place", "country",
                            "plant", "vehicle", "product"]
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
    children :: Array{Node}
end

mutable struct InternalNounNode <: Node
    category :: String
    verb :: String
    preposition :: String
    parent :: Node
    observed_val :: Union{String, Nothing}
end


function get_article(noun)
    if length(noun) < 1
        return ""
    end 
    return in(string(noun[1]), ["a", "e", "i", "o", "u"]) ? "an" : "a"
end

function render_text(node, verbose=true)
    # Renders text as we go based on the parent.
    article = get_article(node.category)
    text = "I $(node.verb) $article $(node.category)"

    if typeof(node) == InternalNounNode
        parent_noun = node.parent.observed_val == nothing ? node.parent.category : node.parent.observed_val
        text = " $(node.preposition) that $parent_noun, $text"
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
    # Try out specific prompts for each category to use the verb. 
    # TODO: consider disallowing the category name itself
    article = get_article(root.category)
    base_prompt = "I $(root.verb) $article $(root.category)."
    if root.category == "store"
        prompt = "$base_prompt Specifically, I $(root.verb) a [?] store." 
        observed_category ~ fill_blank(prompt)
        observed_category_text = "$observed_category store"
    elseif root.category == "room"
        prompt = "$base_prompt Specifically, I $(root.verb) the [?] in my house."
    elseif in(root.category, ["tool", "clothing", "food", "animal", "appliance"])
        prompt = "$base_prompt Specifically, I $(root.verb) a [?]."
    end
    return observed_category, observed_category_text
end
observe_value_root_category_specific(RootNounNode("store", "visited", nothing))
prompt = "An example of a specific kind of room is a [?]room"
prompt = "A specfic example of a store is a [?] store"

fill_nth_blank("I saw an animal. Specifically, I saw a [?]", 1)
println(top_words_xl("An example of a specific job is a [?].", 1)[1:15])
concrete_noun_categories = ["room", "store", "tool", "food", "clothing", "animal",
                            "job", "appliance", "building", "place", "country",
                            "plant", "vehicle", "product"]


@gen function observe_value_root_sharpened(root)
    # Generates root noun observations as generically as possible.
    article = get_article(root.category)
    observed_category ~ fill_blank_sharpened("An example of a specific $(root.category) is a [?].")
    return observed_category
end 

 @gen function observe_value_root_top_examples(root, n=500)
    # Only allows top n examples
    article = get_article(root.category)
    top_examples = top_words_xl("A specific example of $article $(root.category) is a [?], and", 1)[1:n]
    top_examples = filter(x -> x != root.category, top_examples)
    observed_category ~ fill_blank_from_list("A specific example of a $(root.category) is a [?], and", top_examples)
end

@gen function observe_value_root_top_examples_verb(root, n=50)
    # Gets examples, then uses the verb.
    article = get_article(root.category)
    top_examples = top_words_xl("An example of a specific $(root.category) is a [?], and", 1)[1:n]
    top_examples = filter(x -> x != root.category, top_examples)
    observed_category ~ fill_blank_from_list("I $(root.verb) a [?] yesterday. It was a type of $(root.category)", top_examples)
end 

@gen function generate_root_noun_node(verbose=true, use_category=nothing, use_observe=nothing)
    category = use_category == nothing ? {:category} ~ uniform_from_list(concrete_noun_categories) : use_category
    article = get_article(category)
    root_node = RootNounNode(category, "", nothing, [])

    
    # Choose whether to observe.
    observe_root = use_observe == nothing ? {:observe_root} ~ bernoulli(0.5) :  use_observe 
    observed_val = observe_root ? {:observed_val} ~ observe_value_root_top_examples(root_node) : nothing
    root_node.observed_val = observed_val
    
    noun =  root_node.observed_val == nothing ? root_node.category : root_node.observed_val
    verb ~ fill_blank("I [?] a $noun yesterday.")
    root_node.verb = verb
    render_text(root_node, verbose)
    return root_node
end

for category in ["toy"]
    println("Demoing root category: $category")
    for i in 1:15
        generate_root_noun_node(true, category, true)
    end
end

@gen function observe_value_child(child, parent_value)
    # observed_category ~ fill_blank("The specific $(child.category) that I $(child.verb) $(lowercase(child.preposition)) that $parent_value was a [?] yesterday.")
    observed_category ~ fill_blank("The specific $(child.category) that I $(child.verb) $(lowercase(child.preposition)) that $parent_value was a [?] yesterday.")
    return observed_category
end


@gen function observe_value_child_top_examples(child, parent_value, n=500)
    article = get_article(child.category)
    top_examples = top_words_xl("A specific example of $article $(child.category) is a [?], and", 1)[1:n]
    top_examples = filter(x -> x != child.category, top_examples)
    
    observed_category ~ fill_nth_blank_from_list("$(titlecase(child.preposition)) that $parent_value, I $(child.verb) this $(child.category). It was a [?], and", top_examples, 1)
    
    # observed_category ~ fill_nth_blank_from_list("$(titlecase(child.preposition)) that $parent_value, the $(child.category) that I $(child.verb) was a [?], and", top_examples, 1)
    return observed_category
end


@gen function generate_child_noun_node(parent, verbose=true, use_observe=nothing)
    parent_value = parent.observed_val == nothing ? parent.category : parent.observed_val
    best_prepositions = filter(x -> in(x, prepositions), top_words_xl("I [?] a specific [?] [?] that $(parent_value) yesterday.", 3))[1:4]
    preposition ~ fill_nth_blank_from_list("[?] that $(parent_value), I [?] a [?] yesterday.", titlecase.(best_prepositions), 1)
    
    category ~ fill_nth_blank_from_list("$(titlecase(preposition)) that $(parent_value), the [?] that I [?] yesterday was a", concrete_noun_categories, 1)
    verb ~ fill_nth_blank("$(titlecase(preposition)) that $(parent_value), the $category that I [?] yesterday was a", 1)
    
    child_node = InternalNounNode(category, verb, preposition, parent, nothing)
    
    observe_child = use_observe == nothing ? {:observe_child} ~ bernoulli(0.5) :  use_observe 
    observed_val = observe_child ? {:observed_val} ~ observe_value_child_top_examples(child_node, parent_value) : nothing
    child_node.observed_val = observed_val
    
    render_text(child_node, verbose) 
    return child_node
end

demo = ["store"]


for category in demo
    println("Demoing root category: $category")
    for i in 1:10
        root = generate_root_noun_node(true, category, nothing)
        generate_child_noun_node(root, true, true)
        println("\n")
    end
end

@gen function generate_tree(verbose=true, max_depth=2, max_child_nodes=2)
    tree = []
    for depth in 1:max_depth
        println("Now on depth $depth")
        if depth == 1
            nodes = [generate_root_noun_node(verbose, nothing, nothing)]
        else
            nodes = []
            for parent in last(tree)
                num_child_nodes ~ uniform_discrete(0, 2)
                for j in 1:num_child_nodes
                    child = generate_child_noun_node(root, true, nothing)
                    push!(parent.children, child)
                    push!(nodes, child)
                end
            end
        end
        if length(nodes) > 0
            push!(tree, nodes)
        end
    end
end

generate_tree()


