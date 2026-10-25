def is_armstrong_number(number):
    digits = str(number)
    lengthofnumber = len(digits)

    armstrongNumber = sum(int(digit) ** lengthofnumber for digit in digits)

    return armstrongNumber == number


print(is_armstrong_number(153))  # True
