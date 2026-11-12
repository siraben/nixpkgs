import importlib.util
import struct

from PySide6 import QtCore, QtGui, QtWidgets

app = QtWidgets.QApplication([])
label = QtWidgets.QLabel("i686 PySide6 smoke test")
label.resize(320, 100)
label.show()
app.processEvents()
image = label.grab().toImage()
assert not image.isNull()
assert image.width() == 320
is32 = struct.calcsize("P") == 4
for module in ("QtWebEngineCore", "QtWebView"):
    found = importlib.util.find_spec(f"PySide6.{module}") is not None
    assert found == (not is32), (module, found, is32)
print(f"PySide6 {QtCore.__version__}: {struct.calcsize('P') * 8}-bit offscreen widget rendered; optional web modules correct")
