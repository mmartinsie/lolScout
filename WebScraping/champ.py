class Champ:
    # Attributes
    nombre = winrate = banrate = pickrate = None

    # Constructor
    def __init__(self, url, district):
        self.district = district
        self.url = url

    def toString(self):
        print('Nombre:', self.nombre)
        print('Winrate:', self.winrate)
        print('Banrate:', self.banrate)
        print('Pickrate:', self.pickrate)