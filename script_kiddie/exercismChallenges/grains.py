def square(number):
    if number not in range (1,65):
        raise ValueError ("square must be between 1 and 64")
    grainsOnSquare = 2 ** (number - 1)
    return grainsOnSquare

print(square(64))


def total():
    allGrains = 2 ** 64 - 1
    return allGrains