import transformers
import torch
import torch.nn.functional as F
import numpy as np

# We're not training at all, so turn off gradients
# everywhere.
torch.set_grad_enabled(False)

class Memoize:
  def __init__(self, fn):
    self.fn = fn
    self.memo = {}
  def __call__(self, *args):
    if args not in self.memo:
      self.memo[args] = self.fn(*args)
    return self.memo[args]

#########
# GPT-2 #
#########

gpt2_tokenizer = transformers.GPT2Tokenizer.from_pretrained('gpt2')
gpt2_model     = transformers.GPT2LMHeadModel.from_pretrained('gpt2')

def gpt2SampleText(prompt):
  context = torch.tensor(gpt2_tokenizer.encode(prompt), dtype=torch.long).unsqueeze(0).repeat(1,1)
  with torch.no_grad():
    p = 0.01
    while np.random.uniform() > p:
      outputs = gpt2_model(input_ids=context)
      next_token_logits = outputs[0][0,-1,:]
      next_token = torch.multinomial(F.softmax(next_token_logits, dim=-1), num_samples=1)
      context = torch.cat((context, next_token.unsqueeze(0)), dim=1)
      if any(gpt2_tokenizer.decode(next_token.tolist()).endswith(x) for x in ['.', '!', '?']):
        p = 0.6
      else:
        p = 0.01
  return gpt2_tokenizer.decode(context[0].tolist())

def gpt2_next_word_logits(prompt):
  ctx = torch.tensor(gpt2_tokenizer.encode(prompt), dtype=torch.long).unsqueeze(0).repeat(1, 1)
  with torch.no_grad():
    outputs = gpt2_model(input_ids=ctx)
    return outputs[0][0,-1,:]

@Memoize
def gpt2_score_text(prompt, observed):
  with torch.no_grad():
    promptEncoding = gpt2_tokenizer.encode(prompt)
    totalEncoding = gpt2_tokenizer.encode(prompt + observed)
    inputs = torch.tensor(totalEncoding, dtype=torch.long).unsqueeze(0).repeat(1, 1)
    labels = torch.tensor([-1] * len(promptEncoding) + totalEncoding[len(promptEncoding):]).unsqueeze(0).repeat(1,1)
    return float(gpt2_model(input_ids=inputs, labels=labels)[0] * (len(totalEncoding) - len(promptEncoding)))

def scoreTextPieces(pieces):
  # Each piece is (True, ...) or (False, ...)
  with torch.no_grad():
    input_list = []
    label_list = []
    num_labels = 0
    for (is_label, words) in pieces:
      tokens = gpt2_tokenizer.encode("a " + words)[1:]
      input_list.extend(tokens)
      if is_label:
        label_list.extend(tokens)
        num_labels += len(tokens)
      else:
        label_list.extend([-1] * len(tokens))
    inputs = torch.tensor(input_list, dtype=torch.long).unsqueeze(0).repeat(1,1)
    labels = torch.tensor(label_list, dtype=torch.long).unsqueeze(0).repeat(1,1)
    print(inputs)
    print(labels)
    return float(gpt2_model(input_ids=inputs, labels=labels)[0] * num_labels)

##########
# XL-Net #
##########

PADDING_TEXT = "In 1991, the remains of Russian Tsar Nicholas II and his family (except for Alexei and Maria) are discovered. The voice of Nicholas's young son, Tsarevich Alexei Nikolaevich, narrates the remainder of the story. 1883 Western Siberia, a young Grigori Rasputin is asked by his father and a group of men to perform magic. Rasputin has a vision and denounces one of the men as a horse thief. Although his father initially slaps him for making such an accusation, Rasputin watches as the man is chased outside and beaten. Twenty years later, Rasputin sees a vision of the Virgin Mary, prompting him to become a priest. Rasputin quickly becomes famous, with people, even a bishop, begging for his blessing. <eod> </s> <eos>"

xl_tokenizer = transformers.XLNetTokenizer.from_pretrained('xlnet-large-cased')
xl_model = transformers.XLNetLMHeadModel.from_pretrained('xlnet-large-cased')

@Memoize
def xl_masked_word_logits(textWithMask):
  input_ids = torch.tensor(xl_tokenizer.encode(PADDING_TEXT + textWithMask, add_special_tokens=True)).unsqueeze(0)
  mask_idx = input_ids.tolist()[0].index(6)
  perm_mask = torch.zeros((1, input_ids.shape[1], input_ids.shape[1]), dtype=torch.float)
  perm_mask[:, :, mask_idx] = 1.0
  target_mapping = torch.zeros((1, 1, input_ids.shape[1]), dtype=torch.float)
  target_mapping[0, 0, mask_idx] = 1.0
  outputs = xl_model(input_ids, perm_mask=perm_mask, target_mapping=target_mapping)
  next_token_logits = outputs[0]  # Output has shape [target_mapping.size(0), target_mapping.size(1), config.vocab_size]
  return next_token_logits[0][0]

def xl_masked_word_logits_within_candidates(textWithMask, possibilities):
  possible_tokens = torch.tensor([xl_tokenizer.encode(word)[0] for word in possibilities])
  return F.softmax(xlWordLogits(textWithMask)[possible_tokens])

def xl_score_word(textWithMask, word):
  return float(torch.log(F.softmax(xlWordLogits(textWithMask))[xl_tokenizer.encode(word)[0]]))
