import re
import jinja2

templ = jinja2.Template(open('template_start.S', 'r').read())
testlist = open('testlist', 'r').read().split('\n')

tests = []
for test in testlist:
    test = test.strip()
    if test == '':
        continue
    test = re.split(r'\s+', test)
    test_item = {'name': test[0], 'ex': len(test) > 1 and test[1] == '*'}
    tests.append(test_item)

open('start.S', 'w').write(templ.render(tests=tests))