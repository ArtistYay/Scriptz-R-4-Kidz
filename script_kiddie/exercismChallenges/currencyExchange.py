def exchange_money(budget, exchange_rate):
    exchanged_amount = budget / exchange_rate
    return exchanged_amount


def get_change(budget, exchanging_value):
    change = budget - exchanging_value
    return change


def get_value_of_bills(denomination, number_of_bills):
    total_value = denomination * number_of_bills
    return total_value


print(get_value_of_bills(5, 128))


def get_number_of_bills(amount, denomination):
    bill_count = amount // denomination
    return int(bill_count)


print(get_number_of_bills(127.5, 5))


def get_leftover_of_bills(amount, denomination):
    leftover = amount % denomination
    return float(leftover)


def exchangeable_value(budget, exchange_rate, spread, denomination):
    exchange_fee = (exchange_rate / 100) * spread
    exchange_value = exchange_money(budget, exchange_rate + exchange_fee)
    number_of_bills = get_number_of_bills(exchange_value, denomination)
    value_of_bills = get_value_of_bills(denomination, number_of_bills)
    return value_of_bills
