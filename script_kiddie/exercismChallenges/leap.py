def leap_year(year):
    return year % 4 == 0 and year % 100 != 0 or year % 400 == 0
#        return True
#    else:
#        return False
#
#    return leap_year
#
print(leap_year(1800))