def is_armstrong_number(number):
    digits = str(number)
    digit_count = len(digits)

    digit_power_sum = sum(int(digit) ** digit_count for digit in digits)

    return digit_power_sum == number


print(is_armstrong_number(153))  # True
