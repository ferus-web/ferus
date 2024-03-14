#!/usr/bin/env python3

file_name = input("File name >> ")
to_replace = input("Replaces >> ")
to_replace_with = input("With >> ")

file_tmp = open(file_name, "r")
data = file_tmp.read()
file_tmp.close()

with open(file_name, "w") as file:
    file.write(
        data.replace(to_replace, to_replace_with)
    )

print("Done. Replaced {} with {} in file {}".format(to_replace, to_replace_with, file_name))
