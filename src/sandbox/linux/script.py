with open("policyman.nim", "r") as f1:
    cont = f1.read()

cont.replace("ctx.add_rule(", "setSeccomp", -1)

with open("policyman.nim", "w") as f2:
    f2.write(cont)
