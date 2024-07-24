# ---------------------------------------
# 使用示例: bash update.sh 1.0.0 "更新说明"
# ---------------------------------------

version=$1
desc=$2

# 1- Fuck Mac 存储, 先清理文件
echo "清理.DS_Store"
find ./src -name ".DS_Store" -delete

# 2- 更新info.json
jq --arg new_version "$version" '.version = $new_version' ./src/info.json > ./src/temp.json && mv ./src/temp.json ./src/info.json &&

# 3- 生成新版本插件
echo "打包新版本..."
zip -r -j ../plugin/bob-plugin-groq-translate-v$version.bobplugin src/* && 

# 4- 校验, 更新appcast
echo "更新校验..."
sha256=$(shasum -a 256 ../plugin/bob-plugin-groq-translate-v$version.bobplugin | cut -d ' ' -f 1)

download="https://github.com/kentonson/bob-plugin-groq-translate/releases/download/v$version/bob-plugin-groq-translate-v$version.bobplugin"
new_version="{\"version\": \"$version\", \"desc\": \"$desc\", \"sha256\": \"$sha256\", \"url\": \"$download\", \"minBobVersion\": \"1.8.0\"}"


# 更新appcast.json
json_file='appcast.json'
json_data=$(cat $json_file)

updated_json=$(echo $json_data | jq --argjson new_version "$new_version" '.versions = [$new_version] + .versions')
echo $updated_json > $json_file && 


find . -name ".DS_Store" -delete
# 5- 代码打包
echo "代码打包"
if [ ! -d "../package/$version" ]; then mkdir ../package/$version; fi
zip -r ../package/$version/Source\ code.zip src/
tar -zcvf ../package/$version/Source\ code.tar.gz src/ 

# 6- push
echo "更新rep"
find . -name ".DS_Store" -delete
rm -r .vscode
git add .   &&
git commit -m "update to $version $desc" &&
git push origin main &&

# 7- 更新github release
echo "release..."
gh release create v$version ../plugin/bob-plugin-groq-translate-v$version.bobplugin\
                            ../package/$version/Source\ code.tar.gz \
                            ../package/$version/Source\ code.zip \
     -t "v$version" -n "$desc"

