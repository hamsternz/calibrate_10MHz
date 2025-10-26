import matplotlib.pyplot as plt

freq = []
width=60
width2=60*30

f = open('10MHz_fine.log','r')
sec = 0
hrs = []
for row in f:
    row = float(row)
    if row > 9999999.5 and row < 10000000.5:
        freq.append(row)
        hrs.append(sec/3600)
        sec += 1

sec = 0
hrs_filtered = []
filtered = []
for i in range(len(freq)-width):
    filtered.append(sum(freq[i+0:i+width])/width)
    hrs_filtered.append(sec/3600)
    sec += 1
sec = 0

hrs_filtered2 = []
filtered2 = []
for i in range(len(freq)-width2):
    filtered2.append(sum(freq[i+0:i+width2])/width2)
    hrs_filtered2.append(sec/3600)
    sec += 1

plt.scatter(hrs, freq, s=3, label = 'Readings')
plt.plot(hrs_filtered, filtered, color="r", label = '1 min average')
plt.plot(hrs_filtered2, filtered2, color="g", linewidth=3, label = '30 min average')

plt.xlabel('Hours', fontsize = 12)
plt.ylabel('Freq', fontsize = 12)
ax = plt.gca()
#ax.set_ylim([9999999.75,10000000.25])
plt.title('OCXO test', fontsize = 20)
plt.legend()
plt.show()

