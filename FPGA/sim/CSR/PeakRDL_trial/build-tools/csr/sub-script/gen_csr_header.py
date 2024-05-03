#!/usr/bin/env python3

# Generate a CSR header file from the CSR SV file.

import argparse
import re

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate a CSR header file from the CSR SV file.')
    parser.add_argument('file_path', type=str, help='target file path')
    args = parser.parse_args()

    with open(args.file_path, 'r') as file:
        lines = file.readlines()

        # find the line where module definition begins
        mod_begin_line_no = 0
        for i, line in enumerate(lines):
            if re.match(r'\s*module\s*\w+\s*', line):
                mod_begin_line_no = i
                #print('module definition begins at line', mod_begin_line_no)
                break

        # Prepend 'extern' to the module definition line
        lines[mod_begin_line_no] = 'extern ' + lines[mod_begin_line_no]

        # find the line where module port definition ends
        port_end_line_no = 0
        for i, line in enumerate(lines[mod_begin_line_no:]):
            if re.match(r'\s*\)\s*;', line):
                port_end_line_no = mod_begin_line_no + i
                #print('module port definition ends at line', port_end_line_no)
                break

        # Save from line 0 to port_end_line_no as the header file
        header_file_path = args.file_path.replace('.sv', '.svh')
        with open(header_file_path, 'w') as header_file:
            header_file.writelines(lines[:port_end_line_no + 1])
