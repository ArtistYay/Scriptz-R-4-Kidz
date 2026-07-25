""" Lab 4: Write Data to CSV File

**Objective:** Write a list of student records to a CSV file.

**Instructions:** Complete the function that writes student data to a CSV file with headers."""

import csv

def write_student_data(filename, students):
    # Write student data to CSV file
    # Include headers: Name, Age, Grade, GPA
    with open(filename, "w", newline='') as file: # first thing I need to do is open the file and write to it. Make sure there's a new line so data is not written on one line
        writer = csv.writer(file) # I'm not to sure with this line
        writer.writerow(["Name", "Age", "Grade", "GPA"]) # takes the writer variable and writes the header information for the csv

        for student in students: # loops through student_data and gives it the variable of 'student'
            writer.writerow(student) # writes each row based on the list provided

# Test data
student_data = [
    ["Alice Johnson", 20, "Sophomore", 3.7],
    ["Bob Smith", 19, "Freshman", 3.2],
    ["Carol Davis", 21, "Junior", 3.9],
    ["David Wilson", 22, "Senior", 3.5]
]

write_student_data("students.csv", student_data)
print("Data written to students.csv")