import os, re, glob, collections
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),".."))
def rp(p): return os.path.join(ROOT,p.replace("res://",""))
errors=[]
files=glob.glob(ROOT+"/**/*.*",recursive=True)
# 1 paths
for f in files:
    if f.endswith((".tscn",".gd",".tres",".godot")):
        for m in re.findall(r'res://[A-Za-z0-9_/\.\-]+', open(f).read()):
            if not os.path.exists(rp(m)): errors.append(f"missing {m} in {f}")
# 2 tscn structure
scenes={}
for f in glob.glob(ROOT+"/scenes/**/*.tscn",recursive=True):
    t=open(f).read()
    ids=set(re.findall(r'\[ext_resource [^\]]*id="([^"]+)"',t))|set(re.findall(r'\[sub_resource [^\]]*id="([^"]+)"',t))
    for m in re.findall(r'(?:Ext|Sub)Resource\("([^"]+)"\)',t):
        if m not in ids: errors.append(f"undefined res id {m} in {f}")
    nodes=[]; seen=set(); root=None
    for m in re.finditer(r'\[node name="([^"]+)"([^\]]*)\]((?:\n(?!\[).*)*)',t):
        name,attrs,body=m.groups()
        par=re.search(r'parent="([^"]*)"',attrs)
        inst=re.search(r'instance=ExtResource\("([^"]+)"\)',attrs)
        scr=re.search(r'script = ExtResource\("([^"]+)"\)',body)
        if par is None:
            path="."; root=name
        else:
            p=par.group(1)
            if p!="." and p not in seen: errors.append(f"parent {p} not defined before {name} in {f}")
            path=name if p=="." else p+"/"+name
            if path in seen: errors.append(f"duplicate node {path} in {f}")
        seen.add(path)
        uniq="unique_name_in_owner = true" in body
        nodes.append((path,name,inst.group(1) if inst else None,scr.group(1) if scr else None,uniq))
    ext={i:p for p,i in re.findall(r'\[ext_resource [^\]]*path="([^"]+)" id="([^"]+)"',t)}
    scenes[f]=(nodes,ext)
# 3 script node refs
def all_paths(scene_file):
    nodes,ext=scenes[scene_file]
    return {n[0] for n in nodes}, {n[1] for n in nodes if n[4]}
for f,(nodes,ext) in scenes.items():
    for path,name,inst,scr,u in nodes:
        if path!="." or not scr: continue
        sfile=rp(ext[scr]); src=open(sfile).read()
        paths,uniq=all_paths(f)
        for m in re.findall(r'(?<![A-Za-z_])\$([A-Za-z0-9_/]+)',src):
            if m not in paths: errors.append(f"{os.path.basename(sfile)}: ${m} missing in {os.path.relpath(f,ROOT)}")
        for m in re.findall(r'%([A-Z][A-Za-z0-9_]+)',src):
            if m not in uniq: errors.append(f"{os.path.basename(sfile)}: %{m} missing in {os.path.relpath(f,ROOT)}")
        for m in re.findall(r'get_node\("([^"]+)"\)',src):
            if m not in paths: errors.append(f"{os.path.basename(sfile)}: get_node {m} missing in {os.path.relpath(f,ROOT)}")
# 4 class names
cls={}
for f in glob.glob(ROOT+"/scripts/**/*.gd",recursive=True):
    m=re.search(r'^class_name (\w+)',open(f).read(),re.M)
    if m:
        if m.group(1) in cls: errors.append("dup class "+m.group(1))
        cls[m.group(1)]=f
# 5 lint
risky=re.compile(r':=\s*(min|max|clamp|abs|lerp|sign|snapped|wrap)\(|:=.*\.pick_random\(\)|:=.*\.get\(')
for f in glob.glob(ROOT+"/scripts/**/*.gd",recursive=True):
    src=open(f).read()
    for i,l in enumerate(src.split("\n"),1):
        if l.startswith(" "): errors.append(f"space indent {f}:{i}")
        if risky.search(l): errors.append(f"risky infer {os.path.basename(f)}:{i}: {l.strip()}")
    for m in re.findall(r'\b([A-Z][A-Za-z0-9]+)\b',src):
        pass
print("\n".join(errors) or "NO ERRORS"); print(len(cls),"classes")
