yosys -p "prep -top skid_buf; write_json skid_buf.json" skid_buf.sv
netlistsvg skid_buf.json
