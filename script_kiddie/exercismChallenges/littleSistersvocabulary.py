def add_prefix_un(word):
    prefixed_word = f"un{word}"
    return prefixed_word


def make_word_groups(vocab_words):
    separator = " :: " + vocab_words[0]
    return separator.join(vocab_words)


def remove_suffix_ness(word):
    root_word = word[:-4]
    if root_word[-1] == "i":
        root_word = root_word.replace("i", "y")
    return root_word


def adjective_to_verb(sentence, index):
    words = sentence.split()
    adjective = words[index]
    adjective = adjective.rstrip(".")
    return adjective + "en"
