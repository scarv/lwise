import io
import sys
import subprocess
from scanf import scanf

asmfile = str(sys.argv[1])
func_name = sys.argv[2:]

asmfp = open(asmfile, 'r')

#print (func_name)
line = asmfp.readline()
while line != "":
    p =  scanf("%s <%s>:", line)
    if p != None:
        if str(p[1]) in func_name:
            print(str(line[0:-1]))
            start = int(p[0],16)
            line = asmfp.readline()
            while line != "":
                p =  scanf("%s <%s>:", line)
                if p != None:
                    print("size:" + str(int(p[0],16)-start) + "bytes")
                    #print("next function -> " + str(line))
                    break
                line = asmfp.readline()
            continue
    line = asmfp.readline()


