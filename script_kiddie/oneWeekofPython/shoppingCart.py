print('''WELCOME TO OUR USELESS STORE!
*****************************''')

itemPurchasing = input("What item are you purchasing? ")

priceOfItem = float(input(f"What is the price of {itemPurchasing}? "))

quantityOfItem = int(input(f"How many {itemPurchasing} are you buying? "))

subtotal = priceOfItem * quantityOfItem

print(f"Added {quantityOfItem} {itemPurchasing}(s) to shopping cart.")
print(f"Subtotal: ${subtotal}")