import pandas as pd
import plotnine as p9
import matplotlib.pyplot as plt
import json

headers = ['Name', 'Popularity', 'WR','Banrate', 'Main', 'Pentakills', 'Gold', 'Minions', 'Wards', 'Damage', 'Phistory', 'PhistoryDate', 'WRhistory', 'WRhistoryDate', 'BRhistory', 'BRhistoryDate'] 
df = pd.read_csv('champs_information.csv',header=0,names=headers)

# Crea un marco para el gráfico definiendo las variables


# Dibuja los puntos en el marco
print(df["WRhistory"][1])
popularityhistory = json.loads(df["WRhistory"][1])
popularityhistorydate = df["WRhistoryDate"][1]
#popularityhistorydate = json.loads(df["WRhistoryDate"][1].replace('\r', ''))
print(popularityhistorydate)
#print(df.to_string()) 
print("fin")