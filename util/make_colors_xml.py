colors = ["White", "Brown", "Red", "Orange", "Yellow", "Green", "Teal", "Blue", "Purple", "Pink", "Grey", "Black"]

for color in colors:
	template = f"""<Text id="points_{color}" fontSize="42" color="{color}" visibility="{color}">
    Your Score: 0
</Text>"""
	with open("colors_out.xml", "a", encoding="utf-8") as file:
		print(template, file=file)