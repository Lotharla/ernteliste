import sys, os, sqlite3

table = sys.argv[1] if len(sys.argv) > 1 else 'kulturen'
conn = sqlite3.connect(sys.argv[2] if len(sys.argv) > 2 else 'ernteliste.db')
curs = conn.cursor()
curs.execute('DROP TABLE IF EXISTS %s' % table)
curs.execute('CREATE TABLE IF NOT EXISTS %s (art TEXT)' % table)

with open(os.path.join(os.path.dirname(sys.argv[0]), 'assets', '%s.txt' % table)) as f:
    lines = f.read().splitlines()

curs.executemany('INSERT INTO %s (art) VALUES (?)' % table, list(zip(iter(lines))))
conn.commit()
