"""Home » Python Exercises » Python Basic Exercise for Beginners: 40 Coding Problems with Solutions
Python Basic Exercise for Beginners: 40 Coding Problems with Solutions
Updated on: February 8, 2026 | 531 Comments

This Python exercise for beginners is designed to help you practice and improve your coding skills. This page contains over 40 Python exercises curated for beginners.

Each exercise includes a clear problem, a helpful hint, a complete solution, and a detailed explanation. This ensures you not only solve the problem but also understand why the solution works.

Also, See:

Python Exercises: A set of 17 topic specific exercises
Python Quizzes: Solve quizzes to test your knowledge of fundamental concepts.
Basic Python Quiz for beginners
Python Basics: Learn the basics of Python to solve this exercise.
Beginner Python Interview Questions
Tips and essential learning resources accompany each question. These will help you solve the exercise and become more familiar with Python basics.

This Python exercise covers questions on the following topics:

Python for loop and while loop
Python list, set, tuple, dictionary, input, and output
Use Online Python Code Editor to solve exercises.
Let us know if you have any alternative solutions in the comments section below. This will help other developers.

+ Table of Contents (40 Exercises)
Exercise 1. Arithmetic Product and Conditional Logic
Practice Problem: Write a Python function that accepts two integer numbers. If the product of the two numbers is less than or equal to 1000, return their product; otherwise, return their sum.

Exercise Purpose: Learn basic control flow and the use of if-else statements. Understand how code decisions change output based on a mathematical threshold.

Given Input:

Case 1: number1 = 20, number2 = 30
Case 2: number1 = 40, number2 = 30
Expected Output:

The result is 600
The result is 70
Refer:

Accept user input in Python
Calculate an Average in Python
Hint
Solution
Exercise 2. Cumulative Sum of a Range
Practice Problem: Iterate through the first 10 numbers (0–9). In each iteration, print the current number, the previous number, and their sum.

Exercise Purpose: This exercise teaches “State Tracking.” In programming, you often need to remember a value from a previous loop iteration to calculate results in the current one. This is the basis for algorithms like Fibonacci sequences or running totals.

Given Input: Range: numbers = range(10)

Expected Output:

Printing current and previous number sum in a range(10)
Current Number 0 Previous Number 0 Sum: 0
Current Number 1 Previous Number 0 Sum: 1
Current Number 2 Previous Number 1 Sum: 3
....
Current Number 8 Previous Number 7 Sum: 15
Current Number 9 Previous Number 8 Sum: 17
Reference article for help:

Python range() function
Calculate sum and average in Python
Hint
Initialize a variable previous_num to 0 outside the loop.
At the end of each loop iteration, update previous_num with the value of the current_num.
Solution
Exercise 3. String Indexing and Even Slicing
Practice Problem: Display only those characters which are present at an even index number in given string.

Exercise Purpose: Understand how data is stored in memory using zero-based indexing. In most languages, the first character is at position 0, the second at 1, and so on. Mastering indexing is vital for data parsing.

Given Input: String: "pynative"

Expected Output:

Original String is  pynative
Printing only even index chars
p
n
t
v
Hint
Solution
Exercise 4. String Slicing and Substring Removal
Practice Problem: Write a function to remove characters from a string starting from index 0 up to n and return a new string.

Exercise Purpose: This exercise demonstrates how to truncate data strings, a common data-cleaning task.

Given Input:

remove_chars("pynative", 4)
remove_chars("pynative", 2)
Expected Output:

tive
native"""

def remove_chars(user_word, number_start):
    return user_word[number_start:]

print(remove_chars("pynative", 2))