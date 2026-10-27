JACK_VALUE = 11
ROUNDS_AFTER_CURRENT = 2


def get_rounds(number):
    """Create a list containing the current and next two round numbers.

    :param number: int - current round number.
    :return: list - current round and the two that follow.
    """

    rounds = [number]

    for offset in range(1, ROUNDS_AFTER_CURRENT + 1):
        rounds.append(number + offset)
    return rounds


def concatenate_rounds(rounds_1, rounds_2):
    """Concatenate two lists of round numbers.

    :param rounds_1: list - first rounds played.
    :param rounds_2: list - second set of rounds played.
    :return: list - all rounds played.
    """
    return rounds_1 + rounds_2


def list_contains_round(rounds, number):
    """Check if the list of rounds contains the specified number.

    :param rounds: list - rounds played.
    :param number: int - round number.
    :return: bool - was the round played?
    """

    return any(played_round == number for played_round in rounds)


def card_average(hand):
    """Calculate and returns the average card value from the list.

    :param hand: list - cards in hand.
    :return: float - average value of the cards in the hand.
    """

    return sum(hand) / len(hand)


def first_and_last_average(hand):
    """Return the average of the first and last card values.

    :param hand: list - cards in hand.
    :return: float - average of the first and last cards.
    """

    return (hand[0] + hand[-1]) / 2


def middle_card(hand):
    """Return the card at the middle index of the hand.

    :param hand: list - cards in hand.
    :return: int - the 'middle' card value.
    """

    return hand[len(hand) // 2]


def approx_average_is_average(hand):
    """Return if an approximate average equals the calculated average.

    The approximations are the average of the first and last card
    values, and the 'middle' card value.

    :param hand: list - cards in hand.
    :return: bool - does one of the approximate averages equal the
        `true average`?
    """

    true_average = card_average(hand)
    middle_value = middle_card(hand)
    edge_average = first_and_last_average(hand)

    return edge_average == true_average or middle_value == true_average


def average_even_is_average_odd(hand):
    """Return if the even-index average equals the odd-index average.

    :param hand: list - cards in hand.
    :return: bool - are even and odd averages equal?
    """

    if len(hand) < 2:
        raise ValueError("Hand must contain at least 2 cards.")

    even_index_cards = hand[::2]  # indices 0, 2, 4, ...
    odd_index_cards = hand[1::2]  # indices 1, 3, 5, ...

    return card_average(even_index_cards) == card_average(odd_index_cards)


def maybe_double_last(hand):
    """Multiply a Jack card value in the last index position by 2.

    :param hand: list - cards in hand.
    :return: list - hand with Jacks (if present) value doubled.
    """

    if hand[-1] == JACK_VALUE:
        hand[-1] *= 2
    return hand
