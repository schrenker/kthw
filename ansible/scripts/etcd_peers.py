#!/usr/bin/env python3
# [1] = path to inventory
# [2] = etcd members
import sys
import re

with open(sys.argv[1], 'r') as f:
    raw_lines = f.readlines()

lines = []
for line in raw_lines:
    stripped = line.strip()
    if len(stripped) == 0:
        continue
    lines.append(stripped)

found = False
hosts = []
for line in lines:
    if not found:
        if f"[{sys.argv[2]}]" in line:
            found = True
        continue
    else:
        if line[0] == '[' and line[-1] == ']':
            break
        else:
            hosts.append(line)

ip_pattern = re.compile(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})')
ips = []
for host in hosts:
    ips.append(ip_pattern.search(host)[0])

result = ""
for i in range(len(ips)):
    result = result + f"{hosts[i].split()[0]}=https://{ips[i]}:2380,"

print(result[:-1])
