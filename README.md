# Apple 智能辅助开启工具 (Apple Intelligence Enabler)

> 作者 / Author: **liyou2024-ship-it**
> 适用：macOS（首个支持 Apple 智能的版本 ~ macOS 27 Golden Gate Beta 5）
> 平台：Apple Silicon Mac（需 macOS 15.1 Sequoia 及以上）

一个纯命令行的 `.sh` 工具，用上下键菜单即可在你的 Apple Silicon Mac 上启用 / 卸载 Apple 智能（Apple Intelligence）。

## 功能流程

1. 选择语言（中文 / English，双语界面，↑/↓ 选择）
2. 选择操作：① 开启 Apple 智能 ② 卸载 Apple 智能 ③ 关闭工具
   - **风险提示**：选择「开启」或「卸载」后，会先询问「操作有一定风险，你是否愿意承担风险？」（↑/↓ 选择「是 / 否」）。选「否」直接退出，选「是」才继续后续步骤；「关闭工具」不触发此提示。
3. 选择版本：Siri 2.0（macOS 15 Sequoia）/ Siri 3.0（macOS 27 Golden Gate）
4. 选择开启方式：
   - **方法一**：仿美版机型代码（区域设为 US、语言设为英文、写入 eligibility 环境变量）——全机型可用，无需关闭 SIP
   - **方法二**：强制开启相关代码（覆写 FeatureAvailability）——需关闭 SIP 并以可写方式挂载系统卷
5. 自动检测：Apple 芯片、SIP 是否关闭、系统语言是否为英文、Siri 语言与外区 Apple 账户
6. 开启过程无需任何操作
7. 最终确认（开启成功 / 开启失败，任选其一均结束），结束页给出 issue 提交地址

## 使用方法

```bash
chmod +x apple_intelligence_enabler.sh
sudo ./apple_intelligence_enabler.sh
```

工具会自动索取管理员权限（非 root 时通过 `sudo` 重启自身）。

## 重要说明 / 免责声明

- 本工具基于社区公开方法，仅供在你**自己的**设备上使用。
- **方法二需要关闭 SIP（系统完整性保护）** 并以可读写方式挂载系统卷，存在安全风险，请自行评估。
- 关闭 SIP、修改系统文件可能违反 Apple 软件许可协议。
- Apple 智能本身还需要：Apple Silicon 芯片、macOS 15.1+、Siri 语言与系统语言设为 English (US)、以及外区 Apple 账户。
- `featureavailabilityctl` 的覆写 key 与参数可能因 macOS 版本（尤其 Tahoe Beta 系列）不同而变化，遇到问题请到仓库提交 issue。
- 本工具不会收集或上传任何数据。

## 问题反馈

使用中遇到任何问题，请到本仓库提交 issue：
https://github.com/liyou2024-ship-it/apple-intelligence-enabler/issues
