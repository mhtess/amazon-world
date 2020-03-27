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
quantity_noun_categories = ["tool", "food", "clothing", "animal", "appliance", "plant", "vehicle", "product"]
abstract_noun_categories = ["emotion", "subject", "thing", "object"]

prepositions = ["of", "with", "at", "from", "into", "during", "including", "until", "against", "among", "throughout", "despite", "towards", "upon", "to", "in", "for", "on", "by", "about", "like", "through", "over", "before", "between", "after", "since", "without", "under", "within", "along", "following", "across", "behind", "behind", "beyond", "plus", "except", "but", "up", "out", "around", "down", "off", "above", "near"]


#### Associated Quantity
include("associated_quantity.jl")
extract_raw_quantities(["MASS", "CURRENCY", "LENGTH"])


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

mutable struct QuantityNode <: Node
    category :: String
    observed_val :: Float
    unit :: String
end 
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
    children :: Array{Node}
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
    
    also = " "
    if typeof(node) == InternalNounNode
        also = length(node.parent.children) > 0 ? " also " : " "
    end
    text = "I$also$(node.verb) $article $(node.category)"

    if typeof(node) == InternalNounNode
        parent_noun = node.parent.observed_val == nothing ? node.parent.category : node.parent.observed_val
        text = "$text $(lowercase(node.preposition)) that $parent_noun"
    end
    if (node.observed_val != nothing)
        text = "$text, and the $(node.category) was $(get_article(node.observed_val)) $(node.observed_val)"
    end

    text = "$text."
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

@gen function observe_value_root_sharpened(root, t=0.5)
    # Generates root noun observations as generically as possible.
    article = get_article(root.category)
    example_article = fill_blank_from_list("One good example of $article $(root.category) is [?] [?], and ", ["a", "the", "an", ""])
    observed_category ~ fill_blank("One good example of $article $(root.category) is $example_article [?], and", t)
    return observed_category
end 

for category in concrete_noun_categories
    println("Demoing root category: $category")
    for t in [1.0, 0.95, 0.9]
        println("Temperature: $t")
        samples = []
        for i in 1:30
            root = RootNounNode(category, "", nothing, [])
            push!(samples, observe_value_root_sharpened(root, t))
        end
        println(samples)
    end
    println("\n")
end

@gen function observe_value_root_top_examples(root, n=500)
    # Only allows top n examples
    article = get_article(root.category)
    example_article ~ fill_blank_from_list("One good example of $article $(root.category) is [?] [?], and ", ["a", "the", "an", ""])
    top_examples = top_words_xl("One good example of $article $(root.category) is $example_article [?], and", 1)[1:n]
    top_examples = filter(x -> x != root.category, top_examples)
    observed_category ~ fill_blank_from_list("One good example of $article $(root.category) is $example_article [?], and", top_examples)
end

for category in concrete_noun_categories
    println("Demoing root category: $category")
    samples = []
    for n in [1000, 500, 200, 100]
        println("n: $n")
        samples = []
        for i in 1:30
            root = RootNounNode(category, "", nothing, [])
            push!(samples, observe_value_root_top_examples(root, n))
        end
        println(samples)
    end
    println("\n")
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
    
    verb_prompt =  root_node.observed_val == nothing ? "I [?] a $(root_node.category)." : "I [?] a $(root_node.category), and the $(root_node.category) was $(get_article(root_node.observed_val)) $(root_node.observed_val)."
    verb ~ fill_blank(verb_prompt, 1.0)
    root_node.verb = verb
    render_text(root_node, verbose)
    return root_node
end

for category in ["store"]
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
    example_article ~ fill_blank_from_list("One good example of $article $(child.category) is [?] [?], and ", ["a", "the", "an", ""])
    top_examples = top_words_xl("One good example of $article $(child.category) is $example_article [?], and", 1)[1:n]
    top_examples = filter(x -> x != child.category, top_examples)
    
    observed_category ~ fill_nth_blank_from_list("$(titlecase(child.preposition)) that $(parent_value), I $(child.verb) this $(child.category) yesterday, and it was $example_article [?], and", top_examples, 1)
    
    # observed_category ~ fill_nth_blank_from_list("I $(child.verb) a $(child.category) $(lowercase(child.preposition)) that $parent_value, and the $(child.category) was a [?], and", top_examples, 1)
    return observed_category
end


@gen function generate_child_noun_node(parent, verbose=true, use_observe=nothing)
    parent_value = parent.observed_val == nothing ? parent.category : parent.observed_val
    # preposition ~ fill_nth_blank_from_list("[?] that $(parent_value), the [?] that I [?] yesterday was a ", titlecase.(prepositions), 1)
    # latent_category ~ fill_nth_blank_from_list("I [?] this [?] [?] that $(parent_value) yesterday. It was a ", concrete_noun_categories, 2)
    
    latent_category ~ fill_nth_blank_from_list("[?] that $(parent_value) yesterday, I [?] this [?] yesterday, and it was", concrete_noun_categories, 3)
    
    preposition ~ fill_nth_blank_from_list("[?] that $(parent_value), I [?] this $latent_category yesterday, and it was", titlecase.(prepositions), 1)
    
    verb ~ fill_nth_blank("$(titlecase(preposition)) that $(parent_value), I [?] this $latent_category yesterday, and it was", 1)
    
    category ~ fill_nth_blank_from_list("$(titlecase(preposition)) that $(parent_value), I $verb this [?] yesterday, and it was",concrete_noun_categories, 1)

    child_node = InternalNounNode(category, verb, preposition, parent, nothing, [])
    
    observe_child = use_observe == nothing ? {:observe_child} ~ bernoulli(0.5) :  use_observe 
    observed_val = observe_child ? {:observed_val} ~ observe_value_child_top_examples(child_node, parent_value) : nothing
    child_node.observed_val = observed_val
    
    render_text(child_node, verbose) 
    return child_node
end

for category in concrete_noun_categories
    println("Demoing root category: $category")
    for parent_observe in [true, false]
        for i in 1:20
            root = generate_root_noun_node(true, category, parent_observe)
            generate_child_noun_node(root, true, true)
            println("\n")
        end
    end
end

# TODO: quantity nodes.
@gen function generate_tree(verbose=true, max_depth=2, min_child_nodes=1, max_child_nodes=2)
    tree = []
    for depth in 1:max_depth
        if verbose println("Now on depth $depth") end
        if depth == 1
            nodes_at_depth = [{:tree_parent => nothing} ~ generate_root_noun_node(verbose, nothing, nothing)]
        else
            nodes_at_depth = []
            for parent in last(tree)
                num_child_nodes = {:tree_parent => parent => :num_child_nodes} ~ uniform_discrete(min_child_nodes, max_child_nodes) # Maybe this should change with depth or number of other nodes at this level.
                if verbose println("Generating $num_child_nodes children") end
                for j in 1:num_child_nodes
                    if verbose println("Generating $j of $num_child_nodes children") end
                    child = {:tree_parent => parent => :child => j} ~ generate_child_noun_node(parent, true, nothing)
                    push!(parent.children, child)
                    push!(nodes_at_depth, child)
                end
            end    
        end
        push!(tree, nodes_at_depth)
    end
    return tree
end
generate_tree(true, 2, 2)


