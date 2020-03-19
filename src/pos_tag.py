import spacy
import transformers

spacy_en_model = spacy.load("en_core_web_sm")

TAG_TYPES = {
    'noun' : ['NN', 'NNP', 'NNPS', 'NNS'], # Excludes pronouns and numbers
    'prep' : ['RP', 'TO', 'IN'],
    # 'verb' : ['VBD', 'VBN', 'VB', 'VBG', 'VBN', 'VBP', 'VPZ'] 
    'verb' : ['VBD', 'VBN']
}

def pos_tag_vocab(vocab, spacy_model):
    tagged = []
    for i, token in enumerate(vocab):
        if i % 100 == 0:
            print("Tagging {} of {}".format(i, len(vocab)))
        token_doc = spacy_model(token)
        if len(token_doc) < 1:
            tagged.append('NONE')
        else:
            tagged.append(token_doc[0].tag_)
    return tagged

def write_tagged_vocab(vocab, tagged, base_file, tag_type):
    vocab_for_pos = [token for (token, tag) in zip(vocab, tagged) if tag in TAG_TYPES[tag_type]]
    vocab_file = "{}_{}.txt".format(base_file, tag_type)
    with open(vocab_file, 'w') as f:
        [f.write('{}\n'.format(token)) for token in vocab_for_pos]
    
##########
# XL-Net #
##########
xl_tokenizer = transformers.XLNetTokenizer.from_pretrained('xlnet-large-cased')
xl_vocab = [xl_tokenizer.decode(i) for i in range(0, xl_tokenizer.vocab_size)]
xl_tagged = pos_tag_vocab(xl_vocab, spacy_en_model)

base_file = 'vocabs/xl'
for tag_type in TAG_TYPES:
    write_tagged_vocab(xl_vocab, xl_tagged, base_file, tag_type)





    
        