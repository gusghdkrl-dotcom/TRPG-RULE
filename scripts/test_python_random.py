from pathlib import Path
from random import SystemRandom, Random
from itertools import product
from collections import Counter
import hashlib,json,re
# Execute the actual core example rather than only checking its text.
s=Path('rules/01-core.md').read_text();code=re.search(r'```python\n(.*?)\n```',s,re.S)[1];ns={};exec(code,ns)
assert all(1<=v<=6 for v in ns['faces']) and ns['result']==sum(ns['faces'])+1
r=SystemRandom()
for sides in [1,3,5,6,10,100]:
 values=[r.randint(1,sides) for _ in range(200)]
 assert all(type(v) is int and 1<=v<=sides for v in values)
# Exact enumeration proves common-unit-digit candidates preserve old uniform-digit distribution.
for modifier in [0,1,2]:
 for pick in [min,max]:
  direct=Counter();old=Counter()
  for digits in product(range(10),repeat=2+modifier):
   u,*ts=digits
   direct[pick([10*t+u or 100 for t in ts])]+=1
  # Old d100-derived digits have identical independent 10-way probabilities; base 00 handling included.
  for base in range(1,101):
   u=(base%100)%10;t=(base%100)//10
   for more in product(range(10),repeat=modifier):old[pick([10*x+u or 100 for x in (t,*more)])]+=1
  assert direct==old and set(direct)==set(range(1,101))
def seeded(seed,axis,retry=0):
 key=json.dumps(['PYTHON_GENERATION_V1',seed,axis,retry],ensure_ascii=False,separators=(',',':'))
 return Random(int.from_bytes(hashlib.sha256(key.encode('utf-8')).digest(),'big'))
for seed in [1,50,100]:
 a=seeded(seed,'P1.stat_A');b=seeded(seed,'P1.stat_A')
 assert [a.randint(1,100) for _ in range(40)]==[b.randint(1,100) for _ in range(40)]
assert seeded(1,'P1.stat_A').getstate()!=seeded(1,'P1.stat_B').getstate()
assert seeded(1,'P1.stat_A').getstate()!=seeded(1,'P1.stat_A',1).getstate()
assert '## PYTHON_RANDOM_EXECUTION\n' in s and '## DESTINY_DICE_QUEUE\n' not in s
print('PASS: actual Python example; 1,200 bounded draws; exact CoC digit distributions for 0/1/2 modifiers; seeded replay and axis/retry separation')
