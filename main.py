from PyQt5.QtWidgets import QApplication, QMainWindow, QLabel
from PyQt5.QtGui import QPixmap, QPainter, QPen


#---------------------------------------------------------

class Frame(QMainWindow):
    def __init__(self, width=640, height=480, title='Window'):
        super().__init__()
        self.setWindowTitle(title)
        self.graphics_container = QLabel()
        self.pixmap = QPixmap(width, height)
        self.graphics_container.setPixmap(self.pixmap)
        self.keys = []

    def addKey(self, key, pos=None):
        if pos is None:
            pos = len(self.keys)
        self.keys.insert(pos, key)

    def popKey(self, pos=-1):
        self.keys.pop(-1)

    def keyPressEvent(self, event):
        for key in self.keys:
            key(event)

#---------------------------------------------------------

class Hitbox:
    def __init__(self, *data):
        '''data is x1, y1, x2, y2'''

        if len(data) != 4:
            raise AttributeError('Hitbox object always tekes 4 arguments!!')

        self.data = data

    def width(self):
        return self.data[2] - self.data[0]

    def height(self):
        return self.data[3] - self.data[1]

    def center(self):
        return (self.data[0] + self.data[2]) / 2, \
               (self.data[1] + self.data[3]) / 2

    def move(self, vx, vy):
        self.data = (self.data[0] + vx, self.data[1] + vy,
                     self.data[2] + vx, self.data[3] + vy)

    def is_intersection(self, other):
        return abs(self.center()[0] - other.center()[0]) >= (self.width() + other.width()) / 2 \
               or abs(self.center()[1] - other.center()[1]) >= (self.height() + other.height()) / 2

#---------------------------------------------------------

class Snake:

    put_move = {'up': (0, -1), 'right': (1, 0), 'down': (0, 1), 'left': (-1, 0)}

    def __init__(self, x, y, lendth=5, spin=0):
        data = {0: (0, 1), 1: (1, 0)}
        self.color = color
        self.parts = []
        for i in range(length):
            self.parts.add((x + data[spin] * i, y + data[spin] * i))
        self.last_pos = x + data[spin] * length, y + data[spin] * length
        self.rotate = 0

    def setRotate(self, rotate):
        self.rotate = rotate

    def move(self) -> bool:
        self.parts.insert(0, (self.parts[0][0] + self.put_move[self.rotate][0],
                              self.parts[0][1] + self.put_move[self.rotate][1]))
        self.last_pos = self.parts.pop()

    def increase(self):
        self.parts.append(self.last_pos)

#---------------------------------------------------------

class App:
    def __init__(self):
        app = QApplication([])
        screen_size = app.desktop().screenGeometry().width(), app.desktop().screenGeometry().height()
        frame = Frame(*screen_size, 'Snake')
        frame.show()
        app.exec_()

App()