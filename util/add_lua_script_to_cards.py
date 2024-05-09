"""script adds luaScript field to all cards based on Nickname.
"""
import re
import json

from pathlib import Path

pattern = re.compile("^\s*(?P<cardType>.+?)\s+\((?P<cardColor>.+?)\)\s*$")

file_path = Path(r"path/to/saved/json")

with open(file_path, "r", encoding="utf-8") as file:
    text = file.read()

data = json.loads(text)

object_states = data["ObjectStates"]
contained_objects = object_states[0]["ContainedObjects"]

ru_names = {
    "Синий": "blue",
    "Голубой": "teal",
    "Чёрный": "black",
    "Жёлтый": "yellow",
    "Зелёный": "green",
    "Белый": "white",
    "Фиолетовый": "purple",
    "Серый": "gray",
    "Персиковый": "peach",
    "Розовый": "pink",
    "Оранжевый": "orange",
    "Краб": "crab",
    "Русалка": "mermaid",
    "Рыба": "fish",
    "Ракушка": "shell",
    "Пингвин": "penguin",
    "Матрос": "sailor",
    "Капитан": "captain",
    "Акула": "shark",
    "Корабль": "boat",
    "Маяк": "beacon",
    "Осьминог": "octopus",
    "Пловец": "swimmer",
}

for index, object in enumerate(contained_objects):
    if object["LuaScript"]:
        continue
    match = pattern.search(object["Nickname"])
    if match:
        cardType = ru_names.get(match.group("cardType"), "type")
        cardColor = ru_names.get(match.group("cardColor"), "color")
        template = f"cardType       = '{cardType}'\r\ncardColor      = '{cardColor}'\r\nmultiplierType = nil"
        contained_objects[index]["LuaScript"] = template
    else:
        print(f"Error: {object['Nickname']}")

data["ObjectStates"] = contained_objects
   
with open("seasalt.json", "w", encoding="utf-8") as file:
    json.dump(data, file, indent=4, ensure_ascii=False)