# python3.8 -mpip install matplotlib
# python3.8 -mpip install mplcursors
import matplotlib.pyplot as plt
import mplcursors
import csv

plt.title('2017 Formula One World Championship')
plt.xlabel('Races')
plt.ylabel('Points')
# races
x = ['AUS','CHN','BHR','RUS', 'ESP','MON','CAN','AZE','AUT','GBR','HUN',
      'BEL','ITA','SIN','MAL','JPN','USA','MEX','RA','ABU', 'Total']

with open('F1_2017.csv','r') as csvfile:
   plots = csv.reader(csvfile, delimiter=',')
   for row in plots:
      y = []
      last_val = 0
      for col in row[1:]:
          last_val = col or last_val
          y.append(int(last_val))
      plt.plot(x,y,label=row[0])
   plt.legend()
   mplcursors.cursor(hover=True)
   plt.show()
