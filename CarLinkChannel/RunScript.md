#  因为使用了混淆，在debug模式下生成混淆文件需要在build phase中集成如下run scrit,在release模式下运行需要删除这个文件，会导致报错

dir=${SRCROOT}
file_count=0
file_list=`ls -R $dir 2> /dev/null | grep -v '^$'`
for file_name in $file_list
do
temp=`echo $file_name | sed 's/:.*$//g'`
if [ "$file_name" != "$temp" ]; then
cur_dir=$temp
else
if [ ${file_name##*.} = a ]; then
    find -P $dir -name $file_name > tmp.txt
    var=$(cat tmp.txt)
    nm $var > ${file_name}.txt
    rm tmp.txt
fi
if [ ${file_name##*.} = framework ]; then
    find -P $dir -name ${file_name%%.*} > tmp.txt
    var=$(cat tmp.txt)
    nm $var > ${file_name}.txt
    rm tmp.txt
    fi
fi
done



