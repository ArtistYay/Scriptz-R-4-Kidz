from msgraph import GraphServiceClient
from azure.identity import InteractiveBrowserCredential

credential = InteractiveBrowserCredential()

client = GraphServiceClient(credential=credential)

users = client.users.get()

for user in users:
    print(user.sign_in_activity)
    print(user.display_name)
    print(user.user_principal_name)