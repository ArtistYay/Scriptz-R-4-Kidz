"""Lab 1: Date Processing and Finding Oldest Date

**Objective:** Convert a list of date strings to a specified format and find the oldest date.

**Instructions:** Complete the function below that takes a list of date strings in format "MM/DD/YYYY" and 

converts them to "YYYY-MM-DD" format, then returns the oldest date."""

from datetime import datetime

def process_dates(date_list):
    # Convert dates from MM/DD/YYYY to YYYY-MM-DD format
    # Find and return the oldest date in the new format
    pass

# Test data
dates = ["03/15/2023", "12/01/2022", "07/20/2023", "01/05/2022"]
print(process_dates(dates))
# Expected output: "2022-01-05"