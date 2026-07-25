def exchange_money(budget, exchange_rate):
    money = (budget / exchange_rate)
    return(money)

def get_change(budget, exchanging_value):
    money2 = (budget - exchanging_value)
    return(money2)

def get_value_of_bills(denomination, number_of_bills):
    money3 = (denomination * number_of_bills)
    return money3

print(get_value_of_bills(5, 128))
def get_number_of_bills(amount, denomination):
   money4 = (amount // denomination)
   return int(money4)

print(get_number_of_bills(127.5, 5))
def get_leftover_of_bills(amount, denomination):
   money5 = amount % denomination
   return float(money5)

def exchangeable_value(budget, exchange_rate, spread, denomination):
        exchange_fee = (exchange_rate / 100) * spread
        exchange_value = exchange_money(budget, exchange_rate + exchange_fee)
        number_of_bills = get_number_of_bills(exchange_value, denomination)
        value_of_bills = get_value_of_bills(denomination, number_of_bills)
        return value_of_bills
