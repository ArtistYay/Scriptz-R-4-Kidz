def is_armstrong_number(number):
    digits = str(number)
    lengthOfNumber = len(digits)
    
    armstrongNumber = sum(int(digit) ** lengthOfNumber for digit in digits)
    
    return armstrongNumber == number

print(is_armstrong_number(153))  # True