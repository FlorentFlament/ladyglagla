def render(data, perline=8, unit='dc.w'):
    """Renders a array of words to be used by a program."""
    res = []
    for i,v in enumerate(data):
        if i%perline == 0:
            if i != 0:
                res.append('\n')
            res.append(f'\t{unit} ')
        else:
            res.append(', ')
        if (unit == 'dc.b'):
            res.append("${:02x}".format(v))
        else:
            res.append("${:04x}".format(v))
    return ''.join(res)
