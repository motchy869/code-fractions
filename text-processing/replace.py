#coding: utf-8

import re

def main():
    pattern = re.compile(r'rgb\((\d+), (\d+), (\d+)\)')

    with open('style.ini') as f:
        lines = f.readlines()
        for line in lines:
            if line.startswith('color=rgb'):
                m = pattern.search(line)
                r,g,b = m.groups()
                print(f'color=rgb({255-int(r)}, {255-int(g)}, {255-int(b)})')
            else:
                print(line, end='')

if __name__ == '__main__':
    main()