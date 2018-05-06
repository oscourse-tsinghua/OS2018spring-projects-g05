import jinja2

tpl = jinja2.Template(open('boot_ctrl_template.vhd', 'r').read())
bins = open('loader.bin', 'rb').read()

def byte2str(x, w=8):
	return '{{:0>{}}}'.format(w).format(bin(x)[2:])

table = dict()

for k in range(len(bins) // 4):
	table[byte2str(k, w=7)] = ''.join([byte2str(x) for x in bins[(k * 4):(k * 4 + 4)][::-1]])

open('boot_ctrl.vhd', 'w').write(tpl.render(table=table))