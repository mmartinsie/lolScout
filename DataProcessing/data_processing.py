import pandas as pd
import plotnine as p9
import matplotlib.pyplot as plt
import json


def calcularPeso(row):
    return  row.WR + 0.6*row.Popularity + 0.4*row.Banrate + row.Main + 100*row.Pentakills + 0.5*row.Minions + 2*row.Wards

    

headers = ["Name", "Popularity", "WR", "Banrate", "Main", "Pentakills", "Minions", "Wards"] 
df = pd.read_csv('champInfoVersionCSV.csv',sep=';', header=None, names=headers)


# Crea un marco para el gráfico definiendo las variables

top = ["aatrox", "camille", "cho'gath", "darius"," dr. mundo", "fiora", "gangplank", "garen", "gnar", "gwen",  "illaoi", "irelia", "jax", "jayce", "kayle", "kennen", "kled","malphite", "maokai","mordekaiser", "nasus", "ornn", "pantheon", "poppy", "quinn", "renekton", "riven", "rumble", "sett", "shen", "singed", "sion", "tahm kench", "teemo", "trundle", "tryndamere", "urgot", "yorick"]
jung = ["amumu", "diana", "ekko", "elise", "evelynn", "fiddlesticks", "gragas", "graves", "hecarim", "ivern", "jarvan iv", "karthus", "kayn", "kha'zix", "kindred", "lee sin", "lillia", "master yi", "nidalee", "nocturne", "nunu & willump", "olaf", "rammus", "rek'sai", "rengar", "sejuani", "shaco", "shyvana", "skarner", "taliyah", "talon", "udyr", "vi", "viego", "volibear", "warwick", "wukong", "xin zhao", "zac"]
mid = ["ahri", "akali", "akshan", "anivia", "annie", "aurelion sol", "azir", "cassiopeia", "corki", "fizz", "galio", "heimerdinger","kassadin", "katarina", "leblanc", "lissandra", "malzahar","neeko", "orianna", "qiyana", "ryze","sylas", "syndra", "twisted fate","veigar", "vex", "viktor", "vladimir", "xerath","yasuo", "yone", "zed", "ziggs", "zoe"]
adc = ["aphelios", "ashe", "caitlyn", "draven", "ezreal", "jhin", "jinx", "kai'sa", "kalista", "kog'maw", "lucian", "miss fortune", "samira", "sivir", "tristana", "twitch", "varus", "vayne", "xayah", "zeri"]
supp = ["alistar", "bard", "blitzcrank", "brand", "braum", "janna", "karma", "leona","lulu", "lux", "morgana", "nami", "nautilus", "pyke", "rakan", "rell", "renata glasc", "senna", "seraphine","sona", "soraka", "swain", "taric", "thresh", "vel'koz", "yuumi", "zilean", "zyra"]

forbidenChamps=[]

print("Posición elegida (mid,top,jung,adc,supp): ")
posicion = input()
print("Nombre de los 9 campeones elegidos por ambos equipos: ")
a=0
while a < 9:
    forbidenChamps.append(input())
    a=a+1
print("Nombre de los 10 campeones baneados por ambos equipos: ")
a=0
while a < 10:
    forbidenChamps.append(input())
    a=a+1


unoEleccion = ""
dosEleccion = ""
tresEleccion = ""

unoPeso = 0
dosPeso = 0
tresPeso = 0


arrayBusqueda = []


if posicion == "mid":
	arrayBusqueda = mid
elif posicion =="top":
	arrayBusqueda = top
elif posicion =="adc":
	arrayBusqueda = adc
elif posicion =="jung":
	arrayBusqueda = jung
elif posicion =="supp":
	arrayBusqueda = supp

for i in range(len(df.Name)): 
    if (df.Name[i] in arrayBusqueda) and (df.Name[i] not in forbidenChamps):
        peso = calcularPeso(df.iloc[i])
        if (peso > unoPeso):
            tresPeso = dosPeso
            tresEleccion = dosEleccion
            dosPeso = unoPeso
            dosEleccion = unoEleccion
            unoPeso = peso
            unoEleccion = df.Name[i]
        elif (peso < unoPeso) and (peso > dosPeso):
            tresPeso = dosPeso
            tresEleccion = dosEleccion
            dosPeso = peso
            dosEleccion = df.Name[i]
        elif (peso > tresPeso):
            tresPeso = peso
            tresEleccion = df.Name[i]
        
print(f"Las tres mejores elecciones para la posición {posicion} son \n 1) {unoEleccion} \n 2) {dosEleccion} \n 3) {tresEleccion}")

# Dibuja los puntos en el marco
#print("fin")

