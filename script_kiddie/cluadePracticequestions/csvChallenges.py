import csv 

"""Practice Problem: Write a script that reads a CSV file containing employee names and salaries.
 Calculate the average salary and write the results (Original Data + Average) into a new CSV file.

Exercise Purpose: CSV (Comma-Separated Values) is the most common format for data exchange. 
This exercise teaches you to use the built-in csv module, specifically DictReader and DictWriter, 
which allow you to treat rows as dictionaries rather than just lists of strings."""


def write_employee_info (filename):
    with open(filename, "r", newline='') as file:
        employee_salary = []
        reader = csv.DictReader(file)
        for salary in reader:
            employee_salary.append(int(salary['Salary']))
        average = sum(employee_salary) / len(employee_salary)

    with open(filename, 'a', newline='') as file:
        file.write('\n')
        writer = csv.DictWriter(file, fieldnames=salary)
        writer.writerow({"Name": "Average", "Salary": average})

write_employee_info('data.csv')

# Solution

def process_salaries(input_file, output_file):
    salaries = []
    rows = []

    # Read the data
    with open(input_file, mode='r', newline='') as f:
        reader = csv.DictReader(f)
        for row in reader:
            salaries.append(int(row['Salary']))
            rows.append(row)

    avg_salary = sum(salaries) / len(salaries)

    # Write the data
    fieldnames = ['Name', 'Salary']
    with open(output_file, mode='w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
        writer.writerow({'Name': 'Average', 'Salary': avg_salary})
        

# Explanation


"""DictReader: This is safer than basic reader because it lets you access columns by name (row['Salary']) rather than index (row[1]). 
This makes your code break-resistant if columns are rearranged.

newline='': This is a standard Python practice when opening files for the csv module to prevent blank lines from being inserted between rows on different operating systems.

Context Managers: We use with open(...) to ensure the file is closed automatically, preventing data corruption."""
