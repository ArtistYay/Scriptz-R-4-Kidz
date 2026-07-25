def response(hey_bob):
    hey_bob_stripped = hey_bob.strip()

    if not hey_bob_stripped:
        return "Fine. Be that way!"

    is_question = hey_bob_stripped[-1] == "?"
    is_yelling = hey_bob_stripped.isupper()

    if is_yelling and is_question:
        return "Calm down, I know what I'm doing!"
    elif is_yelling:
        return "Whoa, chill out!"
    elif is_question:
        return "Sure."
    else:
        return "Whatever."   