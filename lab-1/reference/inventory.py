import os

folder = os.getcwd()
items = os.listdir(".")

with open("inventory.txt", "w") as f:
    f.write("Inventory for folder: " + folder + "\n")
    f.write("================================\n")
    for name in items:
        f.write(name + "\n")


