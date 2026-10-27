print("""WELCOME TO OUR USELESS STORE!
*****************************""")

item_name = input("What item are you purchasing? ")

item_price = float(input(f"What is the price of {item_name}? "))

item_quantity = int(input(f"How many {item_name} are you buying? "))

subtotal = item_price * item_quantity

print(f"Added {item_quantity} {item_name}(s) to shopping cart.")
print(f"Subtotal: ${subtotal}")
