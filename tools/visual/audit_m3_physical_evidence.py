#!/usr/bin/env python3
"""Independent standard-library QA for actual Godot/Jolt face-result JSONL.

Never creates, rerolls, drops or substitutes a physical die result.
Usage: python3 audit_m3_physical_evidence.py events.jsonl study-report.json
"""
import collections
import json
import math
import pathlib
import sys

def verify(events_path: pathlib.Path, report_path: pathlib.Path) -> dict:
    rows=[json.loads(x) for x in events_path.read_text().splitlines() if x.strip()]
    report=json.loads(report_path.read_text())
    issues=[]
    audit={}
    if report.get("errors"):
        issues.append("Godot/Jolt study itself reported errors")
    for mode in ("D10","D100","D100_PAIR"):
        events=[r for r in rows if r.get("mode")==mode]
        attempts=report.get("attempts",{}).get(mode,{})
        n=len(events)
        if n != int(attempts.get("requested",-1)) or n != int(attempts.get("attempted",-1)) or n != int(attempts.get("completed",-1)):
            issues.append(f"{mode}: actual/attempted/completed/required trial mismatch")
        counts=collections.Counter()
        buckets=[0]*10
        for index,event in enumerate(events):
            faces=event.get("visible_faces",[])
            value=event.get("result")
            if mode=="D10":
                expected=faces[0] if len(faces)==1 and 1<=faces[0]<=10 else None
            elif mode=="D100":
                expected=faces[0] if len(faces)==1 and 1<=faces[0]<=100 else None
            else:
                expected=((faces[0]%10)*10 + faces[1]%10) or 100 if len(faces)==2 and all(1<=f<=10 for f in faces) else None
            if value != expected or not event.get("valid"):
                issues.append(f"{mode} trial {index}: physical face value {expected} differs from logged result {value}")
            if event.get("trial")!=index:
                issues.append(f"{mode} trial index not sequential at {index}")
            if isinstance(value,int) and 1<=value<=(10 if mode=="D10" else 100):
                counts[str(value)]+=1
                buckets[value-1 if mode=="D10" else (value-1)//10]+=1
            else:
                issues.append(f"{mode} trial {index}: invalid result")
        if dict(counts)!=report.get("histograms",{}).get(mode,{}):
            issues.append(f"{mode} Godot histogram does not match actual trial records")
        expected_per_group=n/10
        chi2=sum((count-expected_per_group)**2/expected_per_group for count in buckets) if n else None
        stats=report.get("stats_"+mode,{})
        if chi2 is not None and not math.isclose(chi2,stats.get("chi_square_df9",-1),rel_tol=1e-6,abs_tol=1e-6):
            issues.append(f"{mode} independently calculated chi-square differs from Godot")
        if stats.get("coarse_bias_alert"):
            issues.append(f"{mode} original study flagged a coarse physical distribution anomaly")
        audit[mode]={"n":n,"distinct_results":len(counts),"ten_group_bins":buckets,
            "chi_square_df9":chi2,"max_physical_settle_s":max((e.get("elapsed_s",0) for e in events),default=None),
            "max_recovery_impulses":max((e.get("recoveries",0) for e in events),default=None)}
    if len(rows)!=sum(v["n"] for v in audit.values()):
        issues.append("Unexpected extra/missing/unknown physical trial records")
    n=len(rows)
    result={"status":"PASS" if not issues else "FAIL",
        "provenance":"independent verification of REAL Godot/Jolt upper faces, no synthetic trials",
        "physical_event_rows":n,"original_godot_checks":report.get("checks"),
        "by_mode":audit,"issues":issues,
        "95pct_upper_failure_rate_given_zero_failures_if_iid":1-0.05**(1/n) if n and not issues else None,
        "limitations":["Ten-group chi-square cannot prove all 100 physical D100 face probabilities equal",
           "No on-device OnePlus Nord 3 performance/visual acceptance verified",
           "No real 24 distinct render FPS assertion from nominal 24fps recording"]}
    output=report_path.with_name("independent-physical-evidence-audit.json")
    output.write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n")
    return result

if __name__=="__main__":
    r=verify(pathlib.Path(sys.argv[1]),pathlib.Path(sys.argv[2]))
    print(json.dumps(r,indent=2,ensure_ascii=False))
    if r["issues"]:
        sys.exit(1)
