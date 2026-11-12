import importlib
import importlib.util
import json
import struct
import sys

from PyQt6 import QtCore, QtGui, QtWidgets

bits = struct.calcsize("P") * 8
for module in ("QtQml", "QtQuick", "QtMultimedia", "QtWebSockets"):
    importlib.import_module(f"PyQt6.{module}")
pdf_modules = {}
for module in ("QtPdf", "QtPdfWidgets"):
    found = importlib.util.find_spec(f"PyQt6.{module}") is not None
    assert found == (bits == 64), (module, found, bits)
    if found:
        importlib.import_module(f"PyQt6.{module}")
    pdf_modules[module] = found

app = QtWidgets.QApplication([])
label = QtWidgets.QLabel(f"PyQt6 {QtCore.PYQT_VERSION_STR}: {bits}-bit")
label.resize(320, 100)
label.show()
app.processEvents()
image = label.grab().toImage()
assert not image.isNull()
assert (image.width(), image.height()) == (320, 100)
assert len({image.pixel(x, y) for y in range(100) for x in range(320)}) > 8
assert image.save(sys.argv[1], "PNG")
print(json.dumps({
    "bits": bits,
    "pyqt": QtCore.PYQT_VERSION_STR,
    "qt": QtCore.qVersion(),
    "pdf_modules": pdf_modules,
    "offscreen_widget_rendered": True,
    "image": sys.argv[1],
}, sort_keys=True))
