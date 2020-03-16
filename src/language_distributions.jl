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

struct FillWordXL <: Distribution{String} end

const fill_word_xl = FillWordXL()

function Gen.logpdf(::FillWordXL, s::String, prompt::String)
  return language_models.xl_score_word(replace(prompt, "[?]" => "<mask>"), s)
end

function Gen.random(::FillWordXL, prompt::String)
  language_models.xl_word_logits(replace(prompt, "[?]" => "<mask>"))
end

function Gen.random(::FillWordXL, prompt::String, words)
  words[categorical(py"""fillFromListXL"""(replace(prompt, "[?]" => "<mask>"), words).data.numpy())]
end


function Gen.logpdf(::FillWordXL, s::String, prompt::String, words)
  return in(s, words) ? log(float(py"""fillFromListXL"""(replace(prompt, "[?]" => "<mask>"), words)[findfirst(x -> x == s,  words)])) : begin println("$s is not a valid word here."); -Inf; end
end

(::FillWordXL)(prompt::String) = Gen.random(FillWordXL(), prompt)
(::FillWordXL)(prompt::String, words) = Gen.random(FillWordXL(), prompt, words)

Gen.has_output_grad(::FillWordXL) = false
Gen.has_argument_grads(::FillWordXL) = (false,)


function top_words_xl(prompt)
  prompt_with_mask = replace(prompt, "[?]" => "<mask>")
  wordLogits = language_models.xl_masked_word_logits(prompt_with_mask).data.numpy()
  return reverse([xlvocab[i] for i in sortperm(wordLogits)])
end

function word_probs_xl(prompt)
  prompt_with_mask = replace(prompt, "[?]" => "<mask>")
  logits = language_models.xl_masked_word_logits(prompt_with_mask).data.numpy()
  return softmax(logits)
end

function word_probs_xl(prompt, words)
  prompt_with_mask = replace(prompt, "[?]" => "<mask>")
  logits = language_models.xl_masked_word_logits_within_candidates(prompt_with_mask, words).data.numpy()
  return softmax(logits)
end

@dist fill_blank(prompt) = xlvocab[categorical(word_probs_xl(prompt))]
