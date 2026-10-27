def response(hey_bob):
    message = hey_bob.strip()

    if not message:
        return "Fine. Be that way!"

    is_question = message[-1] == "?"
    is_yelling = message.isupper()

    if is_yelling and is_question:
        return "Calm down, I know what I'm doing!"
    elif is_yelling:
        return "Whoa, chill out!"
    elif is_question:
        return "Sure."
    else:
        return "Whatever."
