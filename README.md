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
7. 可选：将国家代码锁定为美国（↑/↓ 选择「是 / 否」）
   - 好处：启用内置 ChatGPT、Apple News、国际版苹果地图（需配合科学上网）
   - 副作用：将无法使用高德版苹果地图
   - **【重点】iPhone 镜像提醒**：请务必在修改国家代码之前，先完成 iPhone 与 Mac 的配对；否则代码可能匹配不上导致无法连接。
8. **自动检测**：脚本会调用 `featureavailabilityctl` 与系统配置，自动判断 Apple 智能是否已真正启用并给出检测结果（不再让你手动二选一），随后进入结束页

## 使用方法

```bash
chmod +x apple_intelligence_enabler.sh
./apple_intelligence_enabler.sh
```

无需以 sudo 启动脚本。脚本在启动时不会整脚本提权；仅在真正需要管理员权限的步骤（写入系统 plist、设置 launchctl 环境变量、挂载系统卷、覆写 FeatureAvailability）执行时，才会按需弹出 sudo 密码提示（首次输入后会有短时缓存）。

## 重要说明 / 免责声明

- 本工具基于社区公开方法，仅供在你**自己的**设备上使用。
- **方法二需要关闭 SIP（系统完整性保护）** 并以可读写方式挂载系统卷，存在安全风险，请自行评估。
- **按版本选方法**：Siri 2.0（macOS 15 Sequoia）建议优先用方法一（仿美版机型，无需关 SIP，成功率最高）；Siri 3.0（macOS 27 Golden Gate）方法一成功率较低，建议直接尝试方法二（需关 SIP）。
- 关闭 SIP、修改系统文件可能违反 Apple 软件许可协议。
- Apple 智能本身还需要：Apple Silicon 芯片、macOS 15.1+、Siri 语言与系统语言设为 English (US)、以及外区 Apple 账户。
- 锁定国家代码为美国会启用内置 ChatGPT、Apple News、国际版苹果地图（需配合科学上网），但会失去高德版苹果地图；**修改前请务必先完成 iPhone 与 Mac 的配对**，否则 iPhone 镜像可能因代码不匹配而无法连接。
- `featureavailabilityctl` 的覆写 key 与参数可能因 macOS 版本（尤其 Golden Gate Beta 系列）不同而变化，遇到问题请到仓库提交 issue。
- 本工具不会收集或上传任何数据。

### 推荐做法：用「账户分离」稳定开启（而非临时切换）

Apple 智能的可用性由**当前登录的主 Apple 账户（iCloud / 系统账户）地区**实时判定，而不看「媒体与购买」账户。因此「临时登外区账户开启、再换回国区」通常会被资格重判重新锁定。

**稳定可用的正确姿势（Apple 官方支持的机制）：**
- **主账户（系统设置顶部那个 Apple 账户）** 使用**外区 Apple ID**（如美区）→ Apple 智能资格判定合格，且重判也一直合格，不会被锁。
- **媒体与购买（系统设置 → Apple 账户 → 媒体与购买）** 保留**国区 Apple ID** → App Store 仍是国区、国区购买的 app 照常可用。

要点：
- 账户分离是手动在系统设置里完成的，本工具不代为操作；脚本负责在满足条件后真正点亮开关。
- 开启时建议先把系统语言 / Siri 语言设为 English (US) 以确保模型能下载；下载完成后（macOS 27 / Siri 3.0 大概率已支持简体中文）可切回中文 UI 与中文 Siri，实现「中文环境下使用」。
- 真正点亮开关在 macOS 27 上大概率仍需走方法二（强制覆写 + 关闭 SIP）；账户分离解决的是「资格 / 模型下载不被国区卡」，二者配合可行度最高。
- 主账户为外区时，Apple News、Apple TV 等内容区会按外区呈现；但 App Store 因媒体账户为国区而不受影响。

## 问题反馈

使用中遇到任何问题，请到本仓库提交 issue：
https://github.com/liyou2024-ship-it/apple-intelligence-enabler/issues
