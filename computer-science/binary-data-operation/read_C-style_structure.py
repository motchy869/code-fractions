# This script compares RF-IC register setting values.
# For tips for treating C-style struct data in Python3, see: [PythonでバイナリをあつかうためのTips](https://qiita.com/pashango2/items/5075cb2d9248c7d3b5d4)

import dataclasses
import ctypes
from typing import List

LOG_BUF_LEN = 200

class SerialCommand_C(ctypes.Structure):
    _pack_ = 2
    _fields_ = (
        ('cmd1', ctypes.c_uint16),
        ('cmd2', ctypes.c_uint16),
        ('data1', ctypes.c_uint16),
        ('data2', ctypes.c_uint16),
    )

class SerialCommandHistory(ctypes.Structure):
    _pack_ = 2
    _fields_ = (
        ('numEntry', ctypes.c_uint16),
        ('buf', SerialCommand_C * LOG_BUF_LEN)
    )

@dataclasses.dataclass
class RfIcRegVal():
    sysId: int
    regAddr: int
    val: int

def loadData(path: str) -> List[RfIcRegVal]:
    DEV_ID_FOO = 0x0B

    serialCommandHistory = SerialCommandHistory()

    with open(path, 'rb') as file:
        file.readinto(serialCommandHistory)

        numEntry = serialCommandHistory.numEntry
        historyBuf = serialCommandHistory.buf
        rfIcRegVals: List[RfIcRegVal] = []

        for entry in historyBuf:
            devId = entry.cmd1>>8
            if devId == DEV_ID_FOO:
                sysId = 0
                regAddr = (entry.data2>>8)&0x0FF
                val = entry.data2&0x0FF
                rfIcRegVals.append(RfIcRegVal(sysId, regAddr, val))

    return rfIcRegVals

FILE_PATH_SerialCommandHistory_1 = "C:/serialCommandHistory.bin"
grfIcRegVals_1 = loadData(FILE_PATH_SerialCommandHistory_1)
