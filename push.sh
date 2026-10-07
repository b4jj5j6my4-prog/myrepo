#!/bin/bash
# push.sh - 一键生成 Packages 并推送到 GitHub
# 用法: ./push.sh
# 可选: 有代理时 PROXY=http://127.0.0.1:7890 ./push.sh

REPO_DIR="/rootfs/var/mobile/Documents/myrepo"
DEB_DIR="$REPO_DIR/deb"
OUT_PKG="$REPO_DIR/Packages"
OUT_BZ2="$REPO_DIR/Packages.bz2"

cd "$REPO_DIR" || { echo "找不到仓库目录 $REPO_DIR"; exit 1; }

echo "=== 1. 清理旧索引 ==="
rm -f "$OUT_PKG" "$OUT_BZ2"

echo "=== 2. 扫描 deb ==="
shopt -s nullglob
debs=("$DEB_DIR"/*.deb)
if [ ${#debs[@]} -eq 0 ]; then
    echo "deb 目录里没东西"
    exit 1
fi
echo "找到 ${#debs[@]} 个 deb"

echo "=== 3. 生成 Packages ==="
: > "$OUT_PKG"
for deb in "${debs[@]}"; do
    fname="deb/$(basename "$deb")"
    pkg=$(dpkg-deb -f "$deb" Package 2>/dev/null)
    name=$(dpkg-deb -f "$deb" Name 2>/dev/null)
    version=$(dpkg-deb -f "$deb" Version 2>/dev/null)
    arch=$(dpkg-deb -f "$deb" Architecture 2>/dev/null)
    desc=$(dpkg-deb -f "$deb" Description 2>/dev/null | head -1)
    maint=$(dpkg-deb -f "$deb" Maintainer 2>/dev/null)
    author=$(dpkg-deb -f "$deb" Author 2>/dev/null)
    sect=$(dpkg-deb -f "$deb" Section 2>/dev/null)
    dep=$(dpkg-deb -f "$deb" Depends 2>/dev/null)
    size=$(stat -f%z "$deb" 2>/dev/null)

    [ -n "$pkg" ]     && echo "Package: $pkg"        >> "$OUT_PKG"
    [ -n "$name" ]    && echo "Name: $name"          >> "$OUT_PKG"
    [ -n "$version" ] && echo "Version: $version"    >> "$OUT_PKG"
    [ -n "$arch" ]    && echo "Architecture: $arch"  >> "$OUT_PKG"
    [ -n "$sect" ]    && echo "Section: $sect"       >> "$OUT_PKG"
    [ -n "$maint" ]   && echo "Maintainer: $maint"   >> "$OUT_PKG"
    [ -n "$author" ]  && echo "Author: $author"      >> "$OUT_PKG"
    [ -n "$dep" ]     && echo "Depends: $dep"        >> "$OUT_PKG"
    echo "Filename: $fname"  >> "$OUT_PKG"
    [ -n "$size" ]    && echo "Size: $size"          >> "$OUT_PKG"
    [ -n "$desc" ]    && echo "Description: $desc"   >> "$OUT_PKG"
    echo "" >> "$OUT_PKG"
done
echo "Packages: $(wc -l < "$OUT_PKG") 行"

echo "=== 4. 生成 Packages.bz2 ==="
bzip2 -k -f "$OUT_PKG"
echo "已生成: $OUT_BZ2"

echo "=== 5. git 提交 ==="
git add -A
git commit -m "update: $(date '+%Y-%m-%d %H:%M')" >/dev/null 2>&1
echo "已提交"

echo "=== 6. 推送 ==="
if [ -n "$PROXY" ]; then
    echo "使用代理: $PROXY"
    git -c http.proxy="$PROXY" -c https.proxy="$PROXY" push
else
    git push
fi

echo ""
echo "=== 全部完成 ==="
