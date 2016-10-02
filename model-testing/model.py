import argh
import time

# for temp * fuel * COEF
BURN_COEF = ( 1. / 256 ) * ( 1. / 192) * 16 # full temp and full fuel = 64 burn rate
BURN_TO_TEMP_COEF = 3

# for temp * COEF
#BURN_COEF = (

TRANSFER_COEF = 1. / 32 # note total loss is 4 * this

def step():
	maxY = len(grid)
	maxX = len(grid[0])
	dt = [[0 for x in range(maxX)] for y in range(maxY)]
	for y in range(maxY):
		for x in range(maxX):
			temp, fuel = grid[y][x]

			# burn
			if temp >= 64:
				burn_rate = int(temp * (fuel + 16) * BURN_COEF)
				# do we have enough to burn?
				if burn_rate > fuel:
					burn_rate = fuel
				# apply
				grid[y][x] = (temp, fuel - burn_rate)
				dt[y][x] += burn_rate * BURN_TO_TEMP_COEF

			# debug
#			if burn_temp > 0:
#				print burn_temp, fuel,  burn_temp * fuel * BURN_COEF

			# move heat to neighbors
			transfer = max(1, int(temp * TRANSFER_COEF))
			neighbors = 3
			for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]: # no diagonals
				if (0 <= y + dy < maxY) and (0 <= x + dx < maxX):
					dt[y+dy][x+dx] += transfer
					neighbors += 6
				else:
					neighbors += 1
			dt[y][x] -= transfer * neighbors / 6

	# apply dt's
	for y in range(maxY):
		for x in range(maxX):
			grid[y][x] = (min(255, grid[y][x][0] + dt[y][x]), grid[y][x][1])


path_grid = [
	[(32, 0), (32, 0), (32, 0), (32, 0), (32, 0), (32, 0), (32, 0), (32, 0)],
	[(32, 0), (32, 0), (128,64), (32, 50), (32, 50), (32, 50), (32, 50), (32, 0)],
	[(32, 0), (32, 0), (60, 50), (32, 50), (32, 50), (32, 50), (32, 50), (32, 0)],
	[(32, 0), (32, 0), (32, 20), (32, 0), (32, 0), (32, 0), (32, 150), (32, 0)],

	[(32, 0), (32, 0), (32, 10), (32, 0), (32, 0), (32, 0), (32, 150), (32, 0)],
	[(32, 0), (32, 5), (32, 5), (32, 5), (32, 0), (32, 0), (32, 200), (32, 0)],
	[(32, 0), (32, 5), (32, 5), (32, 5), (32, 0), (32, 0), (32, 0), (32, 0)],
	[(32, 0), (32, 5), (32, 5), (32, 5), (32, 0), (32, 0), (32, 0), (32, 0)],
]

def new_sea_grid():
	return [[(32, 64) for x in range(20)] for y in range(18)]

corner_hot_sea_grid = new_sea_grid()
corner_hot_sea_grid[0][0] = (255, 128)

mid_cool_sea_grid = new_sea_grid()
mid_cool_sea_grid[9][9] = (64, 128)

grid = mid_cool_sea_grid

def display(hide):
	def color(c, s, hide):
		return '\x1b[3{}m{}\x1b[m'.format(c, 'XXX' if hide else s)
	def pick_color(temp, fuel):
		tempcolor = {
			0: None,
			1: '3', # yellow
			2: '1', # red
			3: '1;1', # bold red
		}.get(temp/64, '5')
		if tempcolor:
			return tempcolor
		if fuel < 32:
			return '0' # black
		if fuel < 64:
			return '2' # green
		return '2;1' # bold green
		
	def display_line(row):
		temps = [color(pick_color(temp, fuel), '{:03d}'.format(temp), hide) for temp, fuel in row]
		fuels = [color(pick_color(temp, fuel), '{:03d}'.format(fuel), hide) for temp, fuel in row]
		return '{}\n{}'.format(' '.join(temps), ' '.join(fuels))
	lines = map(display_line, grid)
	lines = '\n\n'.join(lines)
	print '\x1b[H\x1b[2J'
	print lines


def main(interval=0., hide=False):
	display(hide=hide)
	while True:
		if interval:
			time.sleep(interval)
		else:
			raw_input()
		step()
		display(hide=hide)

if __name__ == '__main__':
	argh.dispatch_command(main)
