"""Execute the published bounded-composition sampler; no PC gameplay rolls."""
from pathlib import Path
from random import Random
import hashlib,json,re

source=(Path(__file__).resolve().parents[1]/'rules/04-setup.md').read_text()
code=re.search(r'```python\n(.*?)\n```',source,re.S)[1]
ns={};exec(code,ns)
ways,sample=ns['ways'],ns['sample_stats']
# Exact counts, not a tolerance-based frequency test.
assert ways(0,0)==1 and ways(0,1)==0
assert ways(1,0)==1 and ways(1,10)==1 and ways(1,11)==0
assert ways(2,10)==11 and ways(2,0)==1 and ways(2,20)==1
assert sum(ways(8,total) for total in range(81))==11**8
assert all(ways(8,total)==ways(8,80-total) for total in range(81))
def seeded(seed,axis):
    key=json.dumps(['PYTHON_GENERATION_V1',seed,axis,0],ensure_ascii=False,separators=(',',':'))
    return Random(int.from_bytes(hashlib.sha256(key.encode()).digest(),'big'))
for seed in range(1,101):
    drafts=[]
    for label in 'ABC':
        values=sample(seeded(seed,'P1.stat_'+label))
        assert len(values)==8 and sum(values)==400
        assert all(30<=v<=80 and v%5==0 for v in values)
        assert values==sample(seeded(seed,'P1.stat_'+label))
        luck=seeded(seed,'P1.luck_'+label).randint(20,80)
        assert 20<=luck<=80
        drafts.append(values)
    assert len({tuple(x) for x in drafts})==3
print('PASS: published sampler; exact bounded counts/symmetry; 300 valid stat/Luck drafts and seeded replay; no gameplay/AI session executed')
