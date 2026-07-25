#def minutes_to_hours(minutes):
#    # Write your code here.
#    return float(minutes / 60)
#
#
## You may alter the code below to test your solution or print help documentation.
## Only the minutes_to_hours function will be graded for this assessment.
#
#mins = 60
#print(minutes_to_hours(mins))
# help(help)

#def update_log_list(log_list):
#    # Write your code here.
#    for log in log_list:
#        if log["app"] == "webserver":
#            log["level"] = "ERROR"
#        elif log["app"] == "database":
#            log["timestamp"] = "2023-12-07T12:30:00"
#    return log_list
#
# You may alter the code below to test your solution or print help documentation.
# Only the update_log_list function will be graded for this assessment.

#log_sample = [
#     {"app": "webserver", "level": "INFO", "message": "Critical error", "timestamp": "2023-12-07T11:55:00"},
#     {"app": "database", "level": "ERROR", "message": "Database connection lost", "timestamp": "2023-12-07T11:50:00"}]
#
#print(update_log_list(log_sample))
# help(help)

# Write your code here.
def validate_id(id):
    if len(id) != 8:
        return False
    elif id[:3].isupper() and type(int(id[3:])) == int:
        return True
    else:
        return False

# You may alter the code below to test your solution or print help documentation.
# Only the validate_id function will be graded for this assessment.

print(validate_id("HRD00123"))
# help(help)