import sys, os, json, requests

x = '{ "Kalenderwoche":"2023-40", "Einheit":"kg", "Menge":42, "Kultur":"Kartoffel", "Bemerkungen":"ein Haufen Zeug"}'
y = json.loads(x)
# print(y)
# print(json.dumps(y, indent = 4))
z = {
    "Kalenderwoche": '2023-40',
    "Menge": 42,
    "Einheit": "kg",
    "Kultur": 'Kartoffel',
    "Bemerkungen": 'ein Haufen Zeug'
}
assert y == z

with open(os.path.join(os.path.dirname(sys.argv[0]), 'assets', 'config.json')) as f:
    config = json.loads(f.read())
url = f"http://{config['host']}:{config['port']}/{config['service']}"
try:
#    import pdb; pdb.set_trace()
    method = sys.argv[1] if len(sys.argv) > 1 else 'get'
    data = z if method in ['post','put','patch'] else None
    if len(sys.argv) > 2:
        from urllib.parse import urlencode
        url += '?' + urlencode(json.loads(sys.argv[2]))
    if len(sys.argv) > 3:
        data = json.loads(sys.argv[3])
#    headers = {'Content-Type': 'application/json; charset=utf-8'} if method in ['post','put','patch'] else None
    response = requests.request(
        method, 
        url,
        json = data)
    # If the response was successful, no Exception will be raised
    response.raise_for_status()
except requests.exceptions.HTTPError as http_err:
    print(f'{http_err}')
    exit(255)
except Exception as err:
    print(f'Other error occurred on \x1B[3m{url}\x1B[0m : {err}')
    exit(255)
else:
    print(response.text, end='\n')

