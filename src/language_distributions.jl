using Gen
using PyCall

const sys = pyimport("sys")
push!(sys["path"], joinpath(pwd(), "src"))
const language_models = pyimport("language_models")

###########
#  GPT-2  #
###########

struct Elaborate <: Distribution{String} end

const elaborate = Elaborate()

function Gen.logpdf(::Elaborate, s::String, prompt::String)
  return -1 * language_models.gpt2_score_text(prompt, s)
end

function Gen.random(::Elaborate, prompt::String)
  language_models.gpt2SampleText(prompt)
end

(::Elaborate)(prompt::String) = Gen.random(Elaborate(), prompt)

Gen.has_output_grad(::Elaborate) = false
Gen.has_argument_grads(::Elaborate) = (false,)

const gpt2_score_text_pieces = language_models.scoreTextPieces

##########
# XL-Net #
##########

xl_vocab_base_name = "xl"
function pos_vocab_load_tagged_data(vocab_base_name)
    pos_vocab = Dict()
    for k in ["noun", "prep", "verb"]
        vocab_file = "vocabs/$(vocab_base_name)_$(k).txt"
        f = open(vocab_file);
        pos_vocab[k] = readlines(f);
    end
    return pos_vocab
end

softmax(arr) = exp.(arr .- logsumexp(arr))

xlvocab = [language_models.xl_tokenizer.decode(i) for i=0:31999]
xl_pos_vocabs = pos_vocab_load_tagged_data(xl_vocab_base_name)

function word_logits_xl(prompt, which_mask=1)
  prompt_with_mask = replace(prompt, "[?]" => "<mask>")
  logits = language_models.xl_masked_word_logits(prompt_with_mask, which_mask-1).data.numpy()
  return logits
end

function word_logits_xl(prompt, words::Vector{String}, which_mask=1)
  prompt_with_mask = replace(prompt, "[?]" => "<mask>")
  logits = language_models.xl_masked_word_logits_within_candidates(prompt_with_mask, words, which_mask-1).data.numpy()
  return logits
end

function top_words_xl(prompt, which_mask=1)
  logits = word_logits_xl(prompt, which_mask)
  return reverse([xlvocab[i] for i in sortperm(logits)])
end

function top_words_xl(prompt, words::Vector{String}, which_mask=1)
  logits = word_logits_xl(prompt, words, which_mask)
  return reverse([words[i] for i in sortperm(logits)])
end

function word_probs_xl(prompt, which_mask=1, t=1.0)
  return softmax(word_logits_xl(prompt, which_mask) ./ t)
end

function word_probs_xl(prompt, words::Vector{String}, which_mask=1, t = 1.0)
  return softmax(word_logits_xl(prompt, words, which_mask) ./ t)
end


@dist fill_blank(prompt) = xlvocab[categorical(word_probs_xl(prompt))]
@dist fill_blank_temp(prompt, t) = xlvocab[categorical(word_probs_xl(prompt, 1, t))]
@dist fill_blank_from_list(prompt, words) = words[categorical(word_probs_xl(prompt, words))]
@dist fill_blank_from_pos(prompt, pos) = fill_blank_from_list(prompt, getindex(xl_pos_vocabs, pos))
@dist fill_nth_blank(prompt, n) = xlvocab[categorical(word_probs_xl(prompt, n))]
@dist fill_nth_blank_from_list(prompt, words, n) = words[categorical(word_probs_xl(prompt, words, n))]
@dist fill_nth_blank_from_pos(prompt, pos, n) = fill_nth_blank_from_list(prompt, getindex(xl_pos_vocabs, pos), n)



normalize(probs) = probs ./ sum(probs)
function product_of_categoricals(prob_arrays::Vector{Vector{Float32}})
  normalize(reduce((a, b) -> a .* b, prob_arrays))
end
function product_of_log_categoricals(log_probs::Vector{Vector{Float32}})
  softmax(sum(log_probs))
end
function product_of_experts_probs(prompts)
  product_of_log_categoricals([word_logits_xl(args...) for args in prompts])
end
@dist product_of_experts(prompts) = xlvocab[categorical(product_of_experts_probs(prompts))]
#
# product_of_experts([("I am thinking of a [?] I'd like to start.", 1), ("A good example of a kind of store is [?] [?] store.", 2)])
#
# [xlvocab[i] for i in sortperm(product_of_experts_probs([("And [?] the tool, I [?] [?] [?].", 1), ("And I [?] [?] [?] [?] the tool.", 4)]))]
#
#
# sort(product_of_experts_probs([("And [?] the tool, I [?] [?] [?].", 1),
#                                ("And I [?] [?] [?] [?] the tool.", 4)]))
# product_of_experts([("And using the tool, I [?] the [?].", 1),
#                     ("And I [?] the [?] with the tool.", 1),
#                     ("With the tool, I [?] the appliance yesterday.", 1)])
#
# top_words_xl("And using the tool, I [?] the [?] yesterday.")
# top_words_xl("With the tool, I [?] the [?] yesterday.", 1)
