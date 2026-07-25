def get_rounds(number):
    """Create a list containing the current and next two round numbers.

    :param number: int - current round number.
    :return: list - current round and the two that follow.
    """

    rounds = []
    rounds.append(number)

    for item in range(2):
        item += 1
        rounds.append(item + number)
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

    for item in range(len(rounds)):
        for x in rounds:
            if x == number:
                return True
            elif x != number:
                continue
    else:
        return False

def card_average(hand):
    """Calculate and returns the average card value from the list.

    :param hand: list - cards in hand.
    :return: float - average value of the cards in the hand.
    """

    return sum(hand) / len(hand)

def approx_average_is_average(hand):
    """Return if the (average of first and last card values) OR ('middle' card) == calculated average.

    :param hand: list - cards in hand.
    :return: bool - does one of the approximate averages equal the `true average`?
    """

    average = sum(hand) / len(hand)
    middle_card = hand[len(hand) // 2]
    first_and_last_average = (hand[0] + hand[-1]) / 2

    if  first_and_last_average == average or middle_card == average:
        return True
    else:
        return False
    
def average_even_is_average_odd(hand):
    """Return if the (average of even indexed card values) == (average of odd indexed card values).

    :param hand: list - cards in hand.
    :return: bool - are even and odd averages equal?
    """

    if len(hand) < 2:
        raise ValueError("Hand must contain at least 2 cards.")

    even_cards = hand[::2]  # indices 0, 2, 4, ...
    odd_cards = hand[1::2]  # indices 1, 3, 5, ...

    avg_even = sum(even_cards) / len(even_cards)
    avg_odd = sum(odd_cards) / len(odd_cards)

    return avg_even == avg_odd


def maybe_double_last(hand):
    """Multiply a Jack card value in the last index position by 2.

    :param hand: list - cards in hand.
    :return: list - hand with Jacks (if present) value doubled.
    """

    if hand[-1] == 11:
        new_hand = hand[-1] * 2
        hand[-1] = new_hand
        return hand
    else:
        return hand