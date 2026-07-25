"""Write a Python program to read the entire contents of a text file named “sample.txt” and print it to the console."""

def read_file (filename):
    with open (filename, 'r') as file:
        print(file.read())

read_file('jump.txt')

# solution

try:
    with open("jump.txt", 'r') as file:
        content = file.read()
        print(content)
except FileNotFoundError:
    print("Error: 'jump.txt' not found.")