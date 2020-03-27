# Scratch pad for Scribblenauts prompts.
include("language_distributions.jl")

# Types of sentences:
    # Imperative: prepare the schoolhouse for a new year.   
        # Goal subject: "I"; Goal = verb phrase.
    # Imperative, but with a second subject.  "Give the farmer three different farm animals."
                                              # "Help the knight cross the river."
                                              
    # Declarative. "The car needs replacement parts to get back on track." "This woman needs her hair styled"
    # Questions. "What kinds of supplies does a student need?"

# Using multiple hints / goals -- product distribution / mixtures in order to find mutually satisfying likelihoods

# https://scribblenautsanswers.com/scribblenauts-remix
##### 1-1
## 1-1-1-a: Cut the Tree down and grab the real starite!
goal = "cut the tree down"
prompt = "I need to $goal, so I will use [?] [?] to $goal."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 2))[1:15])
# ["machete", "axe", "knife", "tools", "shovel", "hammer", "scissors", "tool", "sword", "blade", "chisel", "tractor", "tree", "spade", "stick"]

prompt = " I need to $goal, so I need the [?] to $goal"
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["axe", "tree", "machete", "tools", "hammer", "knife", "tool", "man", "crane", "guy", "tractor", "shovel", "scissors", "hand", "crew"]

prompt = "I need to $goal, so I will use the [?] to $goal."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["axe", "machete", "knife", "shovel", "hammer", "scissors", "tools", "sword", "tool", "tractor", "blade", "tree", "chisel", "spade", "stick"]
prompt_verb = "I need to $goal, so I will $goal with the [?]"
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt_verb, 1))[1:15])
# ["axe", "hack", "machete", "chop", "hammer", "tree", "knife", "screw", "shovel", "spade", "power", "bare", "electric", "scissors", "blade"]

prompt = "I need to $goal, so I will need some things. In particular, I will need to use a [?] to $goal."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt_verb, 1))[1:15])
# ["axe", "hack", "machete", "chop", "hammer", "tree", "knife", "screw", "shovel", "spade", "power", "bare", "electric", "scissors", "blade"]

##### 1-2
## 1-2-1-a: Give two of them what they would use in their hands!
goal_subj = "the chef"
goal = "give $goal_subj something he would use in his hands"
prompt = " I need to $goal, so I will use the [?] to $goal"
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["knife", "chef", "spoon", "recipe", "cookbook", "microwave", "calculator", "dishwasher", "kitchen", "table", "ingredients", "napkin", "chicken", "analogy", "technique"]

prompt = " I need to $goal, so I need a [?]"
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["spoon", "spat", "napkin", "saucepan", "cookbook", "versatile", "tumble", "saute", "skillet", "kitchen", "machete", "teaspoon", "culinary", "countertop", 
"ratchet"]

goal_subj = "the chef"
goal = "$goal_subj needs something he would use in his hands"
prompt = "$goal, so $goal_subj will use the [?]."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["saucepan", "skillet", "teaspoon", "utensils", "spoon", "cookbook", "tablespoon", "turquoise", "napkin", "machete", "bellow", "chisel", "cellphone", "handkerchief", "saute"]

goal_subj = "the doctor"
goal = "$goal_subj needs something he would use in his hands"
prompt = "$goal, so $goal_subj will use the [?]."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["handkerchief", "pencil", "syringe", "scissors", "spoon", "wrench", "cellphone", "microscope", "calculator", "brush", "teaspoon", "knife", "cotton", "new", "chisel"]

# 1-2-1-b: Give the chef something he would use in the kitchen.
goal = "give the chef something he would use in the kitchen."
prompt = " I need to $goal, so I will use the [?] to $goal"
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["recipe", "chef", "cookbook", "kitchen", "calculator", "tutorial", "ingredients", "dishwasher", "recipes", "menu", "analogy", "dishes", "knife", "dish", "microwave"]

goal_subj = "the chef"
goal_verb_phrase = "use in the kitchen"
goal = "$goal_subj needs something to $goal_verb_phrase, so $goal_subj will use the [?]"
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["recipe", "chef", "cookbook", "kitchen", "calculator", "tutorial", "ingredients", "dishwasher", "recipes", "menu", "analogy", "dishes", "knife", "dish", "microwave"]

# 1-2-1-c: Give the fireman an axe.
goal = "give the fireman an axe"
prompt = " I need to $goal, so I will use the [?] to $goal"
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["axe", "ability", "method", "analogy", "need", "instructions", "algorithm", "idea", "means", "hammer", "trick", "command", "phrase", "tool", "arrow"]


##### 1-3
# 1-3-1-a Prepare the schoolhouse for a new year!
goal = "prepare the schoolhouse for a new year"
prompt = "I need to $goal, so I will need some things. In particular, I will need to use a [?] to $goal."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["broom", "hammer", "tool", "knife", "shovel", "book", "pencil", "calculator", "brush", "calendar", "method", "mop", "mirror", "mortar", "computer"]
goal = "prepare the schoolhouse for a new year"
prompt = "I need to $goal, so I will need some things. In particular, I will need to use a [?]."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["new", "broom", "desk", "table", "mop", "shovel", "pencil", "printer", "computer", "paint", "hammer", "brush", "window", "pen", "fireplace"]

# 1-3-1-b What kinds of supplies does a student need?
goal_subj = "a student"
goal = "$goal_subj needs kinds of supplies"
prompt = "$goal, so $goal_subj needs some things. In particular, $goal_subj needs to use a [?]."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["pencil", "computer", "pen", "broom", "new", "desk", "toilet", "calculator", "shovel", "notebook", "brush", "book", "spoon", "textbook", "printer"]

##### 1-4
# Pit Stop! The car needs replacement parts to get back on track!
goal_subj = "the car"
goal_verb_phrase = "needs replacement parts to get back on track"
goal = "$goal_subj $goal_verb_phrase"
prompt = "$goal, so $goal_subj needs some things. In particular, $goal_subj needs to use the [?]."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["brakes", "engine", "new", "brake", "car", "fuel", "clutch", "parts", "oil", "system", "power", "tires", "gasoline", "accelerator", "gas"]

##### 1-5
# 1-5-1-a: Kick off the beach party!
goal_imperative = "kick off the beach party"
goal_subj = "I"
goal = "$goal_subj need to $goal_imperative"
prompt = "$goal, so $goal_subj need some items. In particular, $goal_subj need the [?]."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["beach", "glasses", "water", "key", "dishes", "cake", "sun", "items", "sand", "food", "sunglasses", "umbrella", "beer", "party", "hat"]

goal = "$goal_subj need to $goal_imperative"
goal = "$goal, so $goal_subj need a [?]."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(goal, 1))[1:15])
# ["bikini", "cocktail", "towel", "cake", "haircut", "beach", "beer", "barbecue", "shower", "hat", "cigarette", "snack", "smile", "shirt", "cupcake"]

##### 1-6
# 1-6-1-a: Give the farmer three different farm animals!
goal_imperative = "give the farmer three different farm animals"
goal_subj = "I"
goal = "$goal_subj need to $goal_imperative"
goal = "$goal, so $goal_subj need a [?]."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(goal, 1))[1:15])
# ["tractor", "farmer", "calculator", "pig", "goat", "dozen", "butcher", "chicken", "new", "pair", "carpenter", "pony", "couple", "buyer", "salesman"]

goal_subj = "the farmer"
goal = "the farmer needs three different farm animals"
goal = "$goal, so $goal_subj needs a [?]."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(goal, 1))[1:15])
# ["tractor", "pig", "calculator", "farmer", "chicken", "goat", "new", "refrigerator", "dozen", "horse", "shotgun", "bicycle", "cow", "carpenter", "fertilizer"]

##### 1-7
# Non-latent version:
# 1-7-1-b: The Brothers particularly enjoy baseball.
goal_subj = "the brothers"
goal_verb_phrase = "enjoy baseball"
goal = "$goal_subj $goal_verb_phrase"
prompt = "$goal, so $goal_subj need some things. In particular, $goal_subj need to use the [?]."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["bat", "baseball", "computer", "pitch", "bathroom", "ball", "bullpen", "telephone", "pen", "internet", "field", "refrigerator", "kitchen", "team", "restroom"]

#### 1-8 
# 1-8-1-a: Maxwell is planning a heist. His gang needs three items.
goal_subj = "Maxwell"
goal_vp = "plans a heist"
goal = "$goal_subj $goal_vp"
prompt = "$goal, so $goal_subj needs some things. In particular, $goal_subj needs to use the [?]."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["computer", "words", "telephone", "phrase", "hammer", "word", "gun", "new", "key", "name", "equipment", "phone", "tools", "item", "wrench"]

# 1-8-1-b Give Maxwell a disguise.
goal_imperative = "give Maxwell a disguise"
goal_subj = "I"
goal = "$goal_subj need to $goal_imperative"
goal = "$goal, so $goal_subj need a [?]."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(goal, 1))[1:15])
["disguise", "cloak", "mask", "costume", "hat", "name", "wizard", "plan", "computer", "new", "wardrobe", "car", "cover", "suit", "mirror"]

# 1-8-1-b Maxwell could use tools to break into a safe.
goal_subj = "Maxwell"
goal_vp = "uses tools to break into a safe"
goal = "$goal_subj $goal_vp"
prompt = "$goal, so $goal_subj needs some things. In particular, $goal_subj needs to use the [?]."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["wrench", "hammer", "tools", "shotgun", "key", "tool", "mouse", "opener", "password", "word", "keys", "drill", "chisel", "flashlight", "words"]

##### 1-9 -- Kinda weird but ok.
# 1-9-1-a: Complete the missing links!
# ---
# 1-9-1-b: This is an evolutionary ladder. lol
goal_declarative = "This is an evolutionary ladder"
goal_subj = "I"
prompt = "$goal_declarative, so $goal_subj need a [?]."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["ladder", "method", "name", "hierarchy", "tree", "graph", "clue", "calculator", "diagram", "microscope", "starter", "new", "tool", "step", "top"]

# 1-9-1-c:  What were the mightiest reptiles? What is the caveman’s closest ancestor?
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl("The mightest reptiles were the [?]", 1))[1:15])
# ["dinosaur", "elephants", "lizard", "birds", "giant", "crocodile", "Mam", "turtle", "giants", "elephant", "dragon", "mammoth", "humans", "horses", "man"]
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl("The caveman’s closest ancestor is the [?]", 1))[1:15])
# ["man", "ho", "cave", "chimpanzee", "mammoth", "modern", "dinosaur", "prehistoric", "Ho", "Human", "proto", "erect", "giant", "Mam", "monkey"]
# lol at ho

##### 1-10
# 1-10-1-a: Help the knight across the lake!
goal_imperative = "help the knight across the lake"
goal_subj = "I"
goal = "$goal_subj need to $goal_imperative"
prompt = "$goal, so $goal_subj need a [?]."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["boat", "knight", "bridge", "sword", "horse", "rope", "catapult", "wizard", "raft", "shield", "ship", "friend", "dagger", "blade", "dragon"]
alt_prompt = "$goal, so $goal_subj need some things. In particular, $goal_subj need a [?] "
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(alt_prompt, 1))[1:15])
# ["sword", "boat", "bridge", "new", "rope", "horse", "spear", "cross", "light", "water", "magic", "silver", "shield", "blade", "lot"]

# 1-10-1-b: Electrocute the Water to destroy the sea creature.
goal_imperative = "electrocute the water to destroy the sea creature"
goal_subj = "I"
goal = "$goal_subj need to $goal_imperative"
prompt = "$goal, so $goal_subj need a [?]."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["generator", "battery", "torch", "charger", "wire", "flashlight", "device", "lamp", "light", "spark", "boat", "cable", "power", "voltage", "solution"]

##### 4-2 -- 3 parts
# 4-2-1-a: The man needs a haircut! Give the stylist tool she needs!
goal_subj = "the man"
goal_verb_phrase = "needs a haircut"
goal = "$goal_subj $goal_verb_phrase"
prompt = "$goal, so $goal_subj needs some items. In particular, $goal_subj needs to use the [?]."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["scissors", "razor", "bathroom", "toilet", "shampoo", "barber", "dryer", "tools", "iron", "brush", "restroom", "salon", "tool", "haircut", "machine"]

# 4-2-2-a: This woman needs her hair styled!
goal_subj = "this woman"
goal_verb_phrase = "needs her hair styled"
goal = "$goal_subj $goal_verb_phrase"
prompt = "$goal, so $goal_subj needs some items. In particular, $goal_subj needs to use the [?]."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# ["product", "products", "scissors", "shampoo", "iron", "brush", "tools", "new", "tool", "items", "salon", "item", "dryer", "brushes", "words"]

# 4-2-3-a Help the stylist make this woman a blonde.
goal_subj = "the stylist"
goal_imperative = "make this woman a blonde"
goal = "$goal_subj needs to $goal_imperative"
prompt = "$goal, so $goal_subj needs some items. In particular, $goal_subj needs to use the [?]."
println(filter(x -> in(x, xl_pos_vocabs["noun"]), top_words_xl(prompt, 1))[1:15])
# "color", "item", "product", "hair", "shampoo", "items", "colors", "products", "words", "blonde", "brush", "white", "red", "colour", "colours"] ??


