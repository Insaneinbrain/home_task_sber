import sys, json
data = json.load(sys.stdin)
print (data)
for key in sorted(data):
    print(data[key] , end='|')
print()
