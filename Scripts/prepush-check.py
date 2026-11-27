import glob, re, subprocess, sys
import yaml

errors = []
files = glob.glob("Signal/Mesh/*.swift") + glob.glob("SignalServiceKit/Mesh/*.swift") + glob.glob("MeshCore/**/*.swift", recursive=True)

for f in files:
    text = open(f).read()
    stripped = re.sub(r'"(?:\\.|[^"\\\n])*"', '""', text)
    if stripped.count("{") != stripped.count("}"):
        errors.append(f"{f}: unbalanced braces")
    if stripped.count("(") != stripped.count(")"):
        errors.append(f"{f}: unbalanced parentheses")
    for i, line in enumerate(stripped.splitlines(), 1):
        if re.search(r'(^|\s)//', line) and not (i == 1 and "swift-tools-version" in line):
            errors.append(f"{f}:{i}: comment")
    if re.search(r'gh[pousr]_[A-Za-z0-9]{20,}|github_pat_', text):
        errors.append(f"{f}: token-like string")

for f in glob.glob(".github/workflows/*.yml"):
    try:
        yaml.safe_load(open(f))
    except Exception as e:
        errors.append(f"{f}: {e}")

pbx = open("Signal.xcodeproj/project.pbxproj").read()
if pbx.count("{") != pbx.count("}"):
    errors.append("pbxproj: unbalanced braces")
ids = re.findall(r'^\t\t([0-9A-F]{24}) /\*', pbx, re.M)
dup = {i for i in ids if ids.count(i) > 1}
if dup:
    errors.append(f"pbxproj: duplicate ids {sorted(dup)[:3]}")
for ref in re.findall(r'productRef = ([0-9A-F]{24})', pbx):
    if not re.search(r'^\t\t%s /\*' % ref, pbx, re.M):
        errors.append(f"pbxproj: dangling productRef {ref}")

for f in glob.glob("Signal/Mesh/*.swift") + glob.glob("SignalServiceKit/Mesh/*.swift"):
    t = open(f).read()
    for m in re.finditer(r'\b(MeshBridge|MeshLocalRegistration|MeshSignalContacts|MeshBackendRegistry|MeshPreKeyStore|MeshInbox|MeshIdentity)\b', t):
        pass

if subprocess.call(["which", "swift"], stdout=subprocess.DEVNULL) == 0:
    if subprocess.call(["swift", "test"], cwd="MeshCore") != 0:
        errors.append("swift test failed")

if errors:
    print("\n".join(errors))
    sys.exit(1)
print("ok")
