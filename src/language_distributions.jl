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

function top_words_xl(prompt, which_mask=1)
  prompt_with_mask = replace(prompt, "[?]" => "<mask>")
  wordLogits = language_models.xl_masked_word_logits(prompt_with_mask, which_mask-1).data.numpy()
  return reverse([xlvocab[i] for i in sortperm(wordLogits)])
end

function word_probs_xl(prompt, which_mask=1)
  prompt_with_mask = replace(prompt, "[?]" => "<mask>")
  logits = language_models.xl_masked_word_logits(prompt_with_mask, which_mask-1).data.numpy()
  return softmax(logits)
end

function pow_with_sign(array, pow)
    sign = cmp.(array, 0)
    return abs.(array).^pow.*sign
end

function word_probs_xl_sharpened(prompt, sharpening_factor=1.05, which_mask=1)
    prompt_with_mask = replace(prompt, "[?]" => "<mask>")
    logits = language_models.xl_masked_word_logits(prompt_with_mask, which_mask-1).data.numpy()
    
    sharpened_logits = pow_with_sign(logits, sharpening_factor)
    return softmax(sharpened_logits)
end


function word_probs_xl(prompt, words::Vector{String}, which_mask=1)
  prompt_with_mask = replace(prompt, "[?]" => "<mask>")
  logits = language_models.xl_masked_word_logits_within_candidates(prompt_with_mask, words, which_mask-1).data.numpy()
  return logits
end

@dist fill_blank_sharpened(prompt) = xlvocab[categorical(word_probs_xl_sharpened(prompt))]

@dist fill_blank(prompt) = xlvocab[categorical(word_probs_xl(prompt))]
@dist fill_blank_from_list(prompt, words) = words[categorical(word_probs_xl(prompt, words))]
@dist fill_blank_from_pos(prompt, pos) = fill_blank_from_list(prompt, getindex(xl_pos_vocabs, pos))
@dist fill_nth_blank(prompt, n) = xlvocab[categorical(word_probs_xl(prompt, n))]
@dist fill_nth_blank_from_list(prompt, words, n) = words[categorical(word_probs_xl(prompt, words, n))]
@dist fill_nth_blank_from_pos(prompt, pos, n) = fill_nth_blank_from_list(prompt, getindex(xl_pos_vocabs, pos), n)