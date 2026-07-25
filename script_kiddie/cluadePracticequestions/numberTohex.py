"""Format a hex color code Write a function called format_hex that accepts a list of three integers (each between 0 and 255) 
representing RGB values and returns a hex color string. The result should be uppercase and start with #."""

# Example inputs and expected outputs:
# format_hex([255, 0, 0])   → '#FF0000'
# format_hex([0, 128, 255]) → '#0080FF'
# format_hex([0, 0, 0])     → '#000000'

def format_hex(rgb):
    # Write your code here.
    
    for number in rgb:
#        int(number)
        if number not in range(0, 256):
            print("Number is not accepted") 
        else:
            hex(number)
    return number

print(format_hex([0, 128, 255]))    