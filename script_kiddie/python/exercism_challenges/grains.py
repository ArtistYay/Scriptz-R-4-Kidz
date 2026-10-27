def square(number):
    if number not in range(1, 65):
        raise ValueError("square must be between 1 and 64")
    grains_on_square = 2 ** (number - 1)
    return grains_on_square


print(square(64))


def total():
    all_grains = 2**64 - 1
    return all_grains
