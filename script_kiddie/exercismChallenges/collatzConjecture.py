def steps(number):
    if number <= 0:
        raise ValueError("Only positive integers are allowed")

    step_count = 0
    while number != 1:
        number = 3 * number + 1 if number % 2 else number / 2
        step_count += 1
    return step_count


print(steps(12))
