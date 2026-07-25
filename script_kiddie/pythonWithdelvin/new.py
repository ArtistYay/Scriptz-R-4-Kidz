class Dog:
    # Parameterized constructor
    def __init__(self, name, breed):
        self.name = name  # Initializes the 'name' attribute
        self.breed = breed # Initializes the 'breed' attribute
        print(f"A new dog named {self.name} has been created!")

    def bark(self):
        print("Woof!")

# Creating an instance of the class calls the __init__ method automatically
my_dog = Dog("Buddy", "Golden Retriever") 
my_dog.bark()