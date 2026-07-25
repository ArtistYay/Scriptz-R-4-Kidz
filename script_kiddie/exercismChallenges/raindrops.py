def convert(number):
    result = []
    if number % 3 == 0:
        result.append("Pling")
    if number % 5 == 0:
        result.append("Plang")
    if number % 7 == 0:
        result.append("Plong")
    elif not result:
        return str(number)
    return "".join(result)

print(convert(34))