class Pokemon:
    # Parameterized constructor
    def __init__(self, name, make, weakness, color):
        self.name = name  # Initializes the 'name' attribute
        self.make = make 
        self.weakness = weakness
        self.color = color
        print(f"{self.name} is a {self.make} type which is weak aganist {self.weakness}!")
        self.my_per = Personality()
        
    def attack(self):
        if self.name == "Bisharp":
            print(f"Bisharp kills Gengar")
        else:
            print(f"Gengar dies to Bisharp")
    
    def shiny(self):
        if self.color == "Blue" or self.color == "White":
            print("This is a shiny")
        else:
            print("This is not a shiny")

class Personality:
    def __init__(self):
        isKind = input("Are you kind? ")
        print("Artist is kind?, " + isKind)
        isSmart = input("Are you smart? ")
        isFun = input("Are you adventorus? ")
        isHumorous = input("Are you funny? ")


class Bisharp(Pokemon):
    def __init__(self):
        super().__init__("Bisharp", "Dark", "Electric", "Blue")

class Gengar(Pokemon):
    def __init__(self):
        super().__init__("Gengar", "Ghost", "Dark", "Purple")
    
#    def bark(self):
#        print("Woof!")

# Creating an instance of the class calls the __init__ method automatically
my_gengar = Gengar()
my_gengar.attack()
my_gengar.shiny()

my_bisharp = Bisharp()
my_bisharp.attack()
my_bisharp.shiny()
#my_dog.bark()
