## JDKSwitcherTool

本工具有两个文件，JDKSwitcher.ps1和Start.bat，程序入口是Start.bat

该程序会自动识别已经安装的JDK版本，注意：JDK需要安装在默认目录：C:\Program Files\Java下才能被识别

程序自动检测PowerShell策略问题

如果系统弹出UAC，请点击：允许

切换后会自动设置环境变量，覆盖掉之前的环境变量，会自动刷新环境变量用于环境生效

![image-20250430171152485](https://typora-typora.oss-cn-chengdu.aliyuncs.com/github-JDKSwitcher/image-20250430171152485.png)

![image-20250430171210816](https://typora-typora.oss-cn-chengdu.aliyuncs.com/github-JDKSwitcher/image-20250430171210816.png)

工具集成了下载链接

自动识别是否安装了JDK，安装了几个JDK，自动识别JDK8

如果没有安装JDK，会自动弹出下载页面

![image-20250430171727660](https://typora-typora.oss-cn-chengdu.aliyuncs.com/github-JDKSwitcher/image-20250430171727660.png)

如果只安装一个JDK，会提示不能切换，只有两个及两个以上才能切换

![image-20250430172103425](https://typora-typora.oss-cn-chengdu.aliyuncs.com/github-JDKSwitcher/image-20250430172103425.png)

安装多个后会自动检测

![image-20250430172313242](https://typora-typora.oss-cn-chengdu.aliyuncs.com/github-JDKSwitcher/image-20250430172313242.png)

如果选择JDK编号错误，会提示[错误] 版本 [ * ] 不存在于可用列表中！

![image-20250430172327232](https://typora-typora.oss-cn-chengdu.aliyuncs.com/github-JDKSwitcher/image-20250430172327232.png)

如果输入当前JDK版本，会提示[!] 你输入的版本与当前环境一致，无需切换！

![image-20250430172425818](https://typora-typora.oss-cn-chengdu.aliyuncs.com/github-JDKSwitcher/image-20250430172425818.png)

输入正确的数字，就可以进行正常切换

![image-20250430172514671](https://typora-typora.oss-cn-chengdu.aliyuncs.com/github-JDKSwitcher/image-20250430172514671.png)

本程序由 Xing 开发