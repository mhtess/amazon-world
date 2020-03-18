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

softmax(arr) = exp.(arr .- logsumexp(arr))

xlvocab = [language_models.xl_tokenizer.decode(i) for i=0:31999]

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

function word_probs_xl(prompt, words::Vector{String}, which_mask=1)
  prompt_with_mask = replace(prompt, "[?]" => "<mask>")
  logits = language_models.xl_masked_word_logits_within_candidates(prompt_with_mask, words, which_mask-1).data.numpy()
  return softmax(logits)
end

@dist fill_blank(prompt) = xlvocab[categorical(word_probs_xl(prompt))]
@dist fill_blank_from_list(prompt, words) = words[categorical(word_probs_xl(prompt, words))]
@dist fill_nth_blank(prompt, n) = xlvocab[categorical(word_probs_xl(prompt, n))]
@dist fill_nth_blank_from_list(prompt, words, n) = words[categorical(word_probs_xl(prompt, words, n))]
