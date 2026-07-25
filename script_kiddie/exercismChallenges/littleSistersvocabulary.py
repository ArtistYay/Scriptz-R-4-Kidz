def add_prefix_un(word):
    unword = f'un{word}'
    return unword

def make_word_groups(vocab_words):
    separator = ' :: ' + vocab_words[0]
    return separator.join(vocab_words)

def remove_suffix_ness(word):
    words = word[:-4]
    if words[-1] == 'i':
      words = words.replace('i', 'y')
    return words

def adjective_to_verb(sentence, index):
    words = sentence.split()
    adjective = words[index]
    adjective = adjective.rstrip('.')
    return adjective + 'en'