<p align="right">
  <img align="right" height="140" src="https://github.com/rooootdev/mond/blob/main/mond.png?raw=true" style="float: right;"/>
</p>

<h1 align="left">mond</h1>
<p align="left">在 iOS 27.0 beta 1 至 beta 4 上修改 MobileGestalt！</p>

本仓库是 [rooootdev/mond](https://github.com/rooootdev/mond) 的简体中文版本，保留原项目作者与贡献者署名。

部分 MobileGestalt 与 RDAR 分辨率修复逻辑参考了 AGPL-3.0 项目 [leminlimez/Nugget](https://github.com/leminlimez/Nugget)，并针对 mond 的端侧写入方式重新实现。缺失偏好文件的实验性创建链路基于 [0xjohnnydev/CFPrefsZeroFile-PoC](https://github.com/0xjohnnydev/CFPrefsZeroFile-PoC) 所公开的技术独立实现，并在触及 RDAR 文件前执行一次可删除的完整写入探针。

持久化写入采用保留原 inode、同步磁盘并回读校验的方式，参考了 MIT 许可项目 [frs0n/GestaltEdit](https://github.com/frs0n/GestaltEdit)。启用持久化模式并应用后，需要立即使用“音量上、音量下、长按侧边键”强制重启；普通关机或重新启动可能让旧缓存覆盖修改。

**计划推出：**<br>
&#45; HouseArrest 文件浏览器（iOS 18 - 27？）

**已知问题：**<br>
&#45; 修改可能会在设备重启后消失<br>
&#45; Apple 智能激活目前不可用

**致谢：**<br>
&#45; [forcequit](https://github.com/forcequitOS)：bad_query 相关工作<br>
&#45; [johnny](https://github.com/0xjohnnydev)：MCM 漏洞类相关工作<br>
&#45; [jailbreak.party](https://github.com/jailbreakdotparty)：PartyUI 与 GestaltView<br>
&#45; [稽品飞车](https://github.com/Github1145142882)：简体中文汉化<br>

## 下载与构建

GitHub Actions 会在每次推送和手动运行时构建免签名 IPA。请在对应构建记录的 Artifacts 中下载 `mond-unsigned-ipa`，然后使用你自己的证书签名并侧载。
