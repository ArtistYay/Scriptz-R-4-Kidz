"""Lab 4: Write Data to CSV File

**Objective:** Write a list of student records to a CSV file.

**Instructions:** Complete the function that writes student data to a CSV file with headers."""

import csv

CSV_HEADERS = ["Name", "Age", "Grade", "GPA"]
OUTPUT_FILENAME = r"script_kiddie\claudePracticequestions\students.csv"


def write_header(csv_writer):
    """Write the column header row."""
    csv_writer.writerow(CSV_HEADERS)


def write_student_rows(csv_writer, students):
    """Write one CSV row per student record."""
    for student_row in students:
        csv_writer.writerow(student_row)


def write_student_data(filename, students):
    """Write student records to a CSV file, header first."""
    # newline="" lets the csv module control line endings itself.
    # Without it, Windows adds an extra blank line between rows.
    with open(filename, "w", newline="") as csv_file:
        # csv.writer turns each list into one comma-separated line,
        # adding quotes when a value contains a comma.
        csv_writer = csv.writer(csv_file)
        write_header(csv_writer)
        write_student_rows(csv_writer, students)


# Test data
student_data = [
    ["Alice Johnson", 20, "Sophomore", 3.7],
    ["Bob Smith", 19, "Freshman", 3.2],
    ["Carol Davis", 21, "Junior", 3.9],
    ["David Wilson", 22, "Senior", 3.5],
]

write_student_data(OUTPUT_FILENAME, student_data)
print(f"Data written to {OUTPUT_FILENAME}")
