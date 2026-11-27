import os
import shutil
import subprocess
import zipfile

BASE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(BASE, "dist", "_build")

# 1) 安装 kafka-python 到构建目录（自带依赖，避免 FunctionGraph 缺包）
subprocess.run(["python", "-m", "pip", "install", "-q", "kafka-python==2.2.15", "-t", SRC], check=True)

# 2) 复制业务代码
shutil.copy(os.path.join(BASE, "index.py"), os.path.join(SRC, "index.py"))
shutil.copy(os.path.join(BASE, "base_adapter.py"), os.path.join(SRC, "base_adapter.py"))

# 3) 清理缓存
for root, dirs, files in os.walk(SRC):
    for d in list(dirs):
        if d == "__pycache__":
            shutil.rmtree(os.path.join(root, d), ignore_errors=True)
    for f in files:
        if f.endswith(".pyc") or f.endswith(".dist-info"):
            p = os.path.join(root, f)
            if os.path.isdir(p):
                shutil.rmtree(p, ignore_errors=True)
            else:
                os.remove(p)

# 4) 打包三个相同内容的 zip（PROVIDER_TYPE 环境变量区分供应商）
os.makedirs(os.path.join(BASE, "dist"), exist_ok=True)
for name in ["gps-adapter", "sim-adapter", "ais140-adapter"]:
    out = os.path.join(BASE, "dist", f"{name}.zip")
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for root, dirs, files in os.walk(SRC):
            for f in files:
                p = os.path.join(root, f)
                z.write(p, os.path.relpath(p, SRC))
    print(out, os.path.getsize(out), "bytes")
