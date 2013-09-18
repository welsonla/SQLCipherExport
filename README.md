![icon](http://ww1.sinaimg.cn/large/6e8de9dbjw1e6qvw7hjmgj2074074mx5.jpg)


##configuration
[http://sqlcipher.net/ios-tutorial](http://sqlcipher.net/ios-tutorial/)



##ScreenShot
1. Drag your database to the first input
2. Input your key

![scrennshot](http://ww1.sinaimg.cn/large/6e8de9dbjw1e7n3eaa3qcj20b10bpq3a.jpg)

#####When export success
You can find a sqlite database named 'developer.db' on your Desktop

```
~/Desktop/developer.db
```

![converting](http://ww4.sinaimg.cn/large/6e8de9dbjw1e7bsk0lxisj20b30bkjrp.jpg)

![success](http://ww4.sinaimg.cn/large/6e8de9dbjw1e6iyseo25vj20cd0caq3e.jpg)


##Release verion is avalible on the folder 'release'
if you could not using Xcode to build it,a release version is avalible on the 'release' folder

##Todo
* live debug
* rekey

##Update

####1.4.1(2013.08.27)
1. 修复点击dock图标窗口仍然无法呼出的bug
2. 添加一个status menu
3. 添加remember key功能，用于储存dbkey

####1.1.2
1. 添加了 GCD
2. 当转换进行中时，设置输入框为不可用
3. 添加动态提示

####1.1.1
1.add an icon :)

####1.0
1. add decode,encode to the sqlite database
2. a simple ui
3. 没有使用GCD
