from pathlib import Path
def txt_to_list(file_path):
    file_list = []
    clean = Path(file_path.strip())
    file_list.append(clean)
    return file_list
    #list_file = []
    #file = open(file_path, "r")
    #line = file.readline()
    #while line:
    #    list_file.append(line.strip())
    #    line = file.readline()
    #file.close()
    #return list_file

# You may alter the code below to view your return value(s).
# Only the txt_to_list function will be graded for this assessment.

print(txt_to_list("log.txt"))
# Expected return: ['2024-01-28 10:15:32 - User login successful', '2024-01-28 11:20:45 - Firewall rule updated', '2024-01-28 12:35:17 - Network switch rebooted', '2024-01-28 13:40:22 - Server backup started', '2024-01-28 14:55:11 - VPN configuration changed', '2024-01-28 15:10:39 - Intrusion detection system alerted', '2024-01-28 16:25:04 - Software update applied to routers']