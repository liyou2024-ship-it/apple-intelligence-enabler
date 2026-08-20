#!/bin/bash
#
# ============================================================================
#  MacOS Apple 智能辅助开启工具 (Apple Intelligence Enabler)
#  作者 / Author: liyou2024-ship-it
#  适用系统 / Target: macOS（首个支持 Apple 智能的版本 ~ macOS 27 Golden Gate Beta 5）
#  运行平台 / Platform: Apple Silicon Mac（需 macOS 15.1 Sequoia 及以上）
# ============================================================================
#
#  说明 / Disclaimer:
#  - 本工具基于社区公开方法，用于在你「自己的」Apple Silicon Mac 上启用 Apple 智能。
#  - 方法一会修改系统区域与语言偏好、写入 eligibility 环境变量；方法二需要关闭 SIP
#    并以可读写方式挂载系统卷，再覆写 FeatureAvailability 配置。
#  - 关闭 SIP、修改系统文件存在安全风险，且可能违反 Apple 软件许可协议，请自行评估。
#  - 本工具不会收集、上传任何数据。
#  - 如启用失败或遇到问题，请到下方仓库提交 issue。
#
set -u

# ========================= 可配置项 / Config =============================
REPO_ISSUES_URL="https://github.com/liyou2024-ship-it/apple-intelligence-enabler/issues"
TOOL_TITLE="Apple智能辅助开启工具 - 作者：liyou2024-ship-it"
# =========================================================================

# 仅支持 macOS
if [ "$(uname)" != "Darwin" ]; then
  echo "错误：本工具仅支持 macOS 系统。" >&2
  exit 1
fi

# 说明：本工具不在启动时整脚本提权。
# 仅在真正需要管理员权限的步骤（写系统 plist / launchctl / 挂载系统卷 / 覆写 featureavailabilityctl）前按需调用 sudo。
# runp: 已是 root 时直接执行，否则加 sudo（首次会提示输入密码，之后有缓存）
runp() { if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi; }

# 语言: zh / en
LANG_CODE="zh"

# ---------- 字符串资源 ----------
load_strings() {
  if [ "$LANG_CODE" = "en" ]; then
    S_WELCOME="Welcome. Please choose your language:"
    S_MOVE_HINT="Use UP/DOWN to move, Enter to confirm"
    S_CHOOSE_ACTION="Please choose an operation:"
    S_ACT_ENABLE="1. Enable Apple Intelligence"
    S_ACT_UNINSTALL="2. Uninstall Apple Intelligence"
    S_ACT_CLOSE="3. Close tool"
    S_CHOOSE_VERSION="Which version of Apple Intelligence do you want to enable?"
    S_VER_SIRI2="Siri 2.0 (macOS 15 Sequoia series)"
    S_VER_SIRI3="Siri 3.0 (macOS 27 Golden Gate series)"
    S_CHOOSE_METHOD="Please choose the enable method:"
    S_METHOD1="Method 1: US-model device code (works on all models)"
    S_METHOD2="Method 2: Force-enable code (try if Method 1 fails)"
    S_DETECTING="Detecting environment..."
    S_DET_CHIP="Apple Silicon (Apple chip)"
    S_DET_CHIP_WARN="Apple Intelligence requires Apple Silicon"
    S_DET_SIP="System Integrity Protection (SIP) disabled"
    S_DET_SIP_WARN="Method 2 needs SIP off; will likely fail"
    S_DET_SYSLANG="System preferred language is English"
    S_DET_LANG_WARN="Set language/region to English (US) for best result"
    S_DET_SIRILANG="Siri language is English (US)"
    S_DET_APPLEID="Using a non-China Apple Account"
    S_DET_DONE="Detection complete. Starting to enable, please wait..."
    S_ENABLING="Enabling Apple Intelligence... please do NOT operate, wait..."
    S_APPLY_M1="Applying Method 1: US-model device code"
    S_APPLY_M2="Applying Method 2: Force-enable overrides"
    S_UNINSTALLING="Reverting Apple Intelligence modifications..."
    S_VERIFYING="Auto-detecting whether Apple Intelligence is actually enabled..."
    S_VERIFY_OK="Apple Intelligence detected as ENABLED (relevant feature flags are on). If it still doesn't show in System Settings, reboot or re-login and check again."
    S_VERIFY_FAIL="Could not confirm Apple Intelligence is enabled. The current method may not apply to your macOS version, or prerequisites (Apple Silicon / English language / non-China Apple Account) may still be unmet. Try Method 2 or open an issue on the repo."
    S_END="Script finished. If you have any issues, please submit an issue at:"
    S_RISK="This operation carries some risk. Are you willing to accept it?"
    S_RISK_YES="Yes - I accept the risk and continue"
    S_RISK_NO="No - Exit the tool"
    S_REGION_BENEFIT="Benefit: enables built-in ChatGPT, Apple News, and international Apple Maps (requires VPN)"
    S_REGION_SIDE="Side effect: the Gaode (AMap) version of Apple Maps will no longer be available"
    S_REGION_WARN_REQ="[Requirement] Before changing the country code, make sure your iPhone is already paired with this Mac."
    S_REGION_WARN_REASON="[Reason] Changing the country code may cause the iPhone and Mac codes to mismatch, breaking the connection."
    S_REGION_ASK="Do you want to lock the device country code to the United States?"
    S_REGION_YES="Yes - Lock to US"
    S_REGION_NO="No - Skip"
    S_REGION_APPLYING="Locking country code to United States..."
    S_REGION_DONE="Done: country code locked to United States."
    S_REGION_SKIP="Skipped: country code not changed."
  else
    S_WELCOME="欢迎使用，请选择你的语言："
    S_MOVE_HINT="使用 ↑/↓ 选择，回车确认"
    S_CHOOSE_ACTION="请选择要完成的操作："
    S_ACT_ENABLE="1. 开启 Apple 智能"
    S_ACT_UNINSTALL="2. 卸载 Apple 智能"
    S_ACT_CLOSE="3. 关闭工具"
    S_CHOOSE_VERSION="你要开启哪版的 Apple 智能？"
    S_VER_SIRI2="Siri 2.0（macOS 15 Sequoia 系列）"
    S_VER_SIRI3="Siri 3.0（macOS 27 Golden Gate 系列）"
    S_CHOOSE_METHOD="请选择开启方式："
    S_METHOD1="方法一：仿美版机型代码（全版本机型都可）"
    S_METHOD2="方法二：强制开启相关代码（若方法一失败，可尝试方法二）"
    S_DETECTING="正在检测运行环境..."
    S_DET_CHIP="Apple 芯片 (Apple Silicon)"
    S_DET_CHIP_WARN="Apple 智能需要 Apple 芯片"
    S_DET_SIP="系统完整性保护 (SIP) 已关闭"
    S_DET_SIP_WARN="方法二需关闭 SIP，否则很可能失败"
    S_DET_SYSLANG="系统首选语言为英文"
    S_DET_LANG_WARN="建议将语言/地区设为 English (US)"
    S_DET_SIRILANG="Siri 语言为英文 (English US)"
    S_DET_APPLEID="使用外区 Apple 账户"
    S_DET_DONE="检测完成，即将开始开启，请稍候..."
    S_ENABLING="正在开启 Apple 智能，请勿操作，请稍候..."
    S_APPLY_M1="正在应用 方法一：仿美版机型代码"
    S_APPLY_M2="正在应用 方法二：强制开启相关代码"
    S_UNINSTALLING="正在卸载 Apple 智能相关修改..."
    S_VERIFYING="正在自动检测 Apple 智能是否已真正启用..."
    S_VERIFY_OK="检测到 Apple 智能已启用（相关特性标志已开启）。如系统设置中仍未出现，请重启或重新登录后再确认。"
    S_VERIFY_FAIL="未能确认 Apple 智能已启用。可能当前方法不适用于您的系统版本，或仍需满足 Apple 芯片 / 英文语言 / 外区账户等条件。可尝试方法二或到仓库提交 issue。"
    S_END="脚本运行结束。若您在使用过程中有任何问题，请登录以下 Github 仓库提交 issue："
    S_RISK="操作有一定风险，你是否愿意承担风险？"
    S_RISK_YES="是 (Yes) - 我愿意承担风险并继续"
    S_RISK_NO="否 (No) - 退出工具"
    S_REGION_BENEFIT="好处：启用内置 ChatGPT、Apple News、国际版苹果地图（需配合科学上网）"
    S_REGION_SIDE="副作用：将无法使用高德版苹果地图"
    S_REGION_WARN_REQ="[要求] 请务必在修改国家代码之前，先完成 iPhone 与 Mac 的配对。"
    S_REGION_WARN_REASON="[原因] 若修改国家代码，可能导致 iPhone 与 Mac 的代码匹配不上，从而无法连接。"
    S_REGION_ASK="您是否要将设备的国家代码锁定为美国？"
    S_REGION_YES="是 (Yes) - 锁定为美国"
    S_REGION_NO="否 (No) - 跳过"
    S_REGION_APPLYING="正在将国家代码锁定为美国..."
    S_REGION_DONE="已完成：国家代码已锁定为美国。"
    S_REGION_SKIP="已跳过：未修改国家代码。"
  fi
}

# ---------- 菜单函数（上下键 + 回车；显示走 /dev/tty，返回值走 stdout）----------
menu() {
  local prompt="$1"; shift
  local opts=("$@")
  local n=${#opts[@]}
  local sel=0 k
  tput civis >/dev/tty 2>/dev/null
  while true; do
    clear >/dev/tty
    echo "$TOOL_TITLE" >/dev/tty
    echo "------------------------------------------------" >/dev/tty
    echo "$prompt" >/dev/tty
    echo "" >/dev/tty
    local i
    for i in "${!opts[@]}"; do
      if [ "$i" -eq "$sel" ]; then
        printf "  \033[1;36m>\033[0m %s\n" "${opts[$i]}" >/dev/tty
      else
        printf "    %s\n" "${opts[$i]}" >/dev/tty
      fi
    done
    echo "" >/dev/tty
    echo "  $S_MOVE_HINT" >/dev/tty
    IFS= read -rsn1 k </dev/tty
    if [ "$k" = $'\e' ]; then
      IFS= read -rsn2 k </dev/tty
    fi
    case "$k" in
      '[A') sel=$(( (sel - 1 + n) % n )) ;;
      '[B') sel=$(( (sel + 1) % n )) ;;
      '') break ;;
    esac
  done
  tput cnorm >/dev/tty 2>/dev/null
  echo "$sel"
}

trap 'tput cnorm >/dev/tty 2>/dev/null; exit 130' INT

# ---------- 检测 ----------
run_detection() {
  echo "$S_DETECTING"
  echo "------------------------------------------------"
  local chip; chip=$(uname -m)
  if [ "$chip" = "arm64" ]; then
    echo "  [OK] $S_DET_CHIP"
  else
    echo "  [XX] $S_DET_CHIP ($chip) - $S_DET_CHIP_WARN"
  fi
  local sip; sip=$(csrutil status 2>/dev/null)
  if echo "$sip" | grep -qi "disabled"; then
    echo "  [OK] $S_DET_SIP"
  else
    echo "  [!!] $S_DET_SIP - $S_DET_SIP_WARN"
  fi
  local lang; lang=$(/usr/bin/defaults read /Library/Preferences/.GlobalPreferences.plist AppleLanguages 2>/dev/null | head -1)
  if echo "$lang" | grep -qi "en"; then
    echo "  [OK] $S_DET_SYSLANG"
  else
    echo "  [!!] $S_DET_SYSLANG - $S_DET_LANG_WARN"
  fi
  echo "  [..] $S_DET_SIRILANG"
  echo "  [..] $S_DET_APPLEID"
  echo "------------------------------------------------"
  echo "$S_DET_DONE"
  sleep 3
}

# ---------- 查找 featureavailabilityctl ----------
find_fac() {
  local p
  for p in \
    "/System/Library/PrivateFrameworks/FeatureAvailability.framework/Versions/A/Support/featureavailabilityctl" \
    "/System/Library/PrivateFrameworks/FeatureAvailability.framework/Support/featureavailabilityctl"; do
    if [ -x "$p" ]; then echo "$p"; return; fi
  done
  echo ""
}

# ---------- 方法核心 ----------
apply_common() {
  # 仿美版机型 / 区域与语言（以下均为需管理员权限的操作，按需 sudo）
  runp /usr/bin/defaults write /Library/Preferences/.GlobalPreferences.plist CountryCode -string "US"
  runp /usr/bin/defaults write /Library/Preferences/.GlobalPreferences.plist AppleLanguages -array "en-US" "zh-Hans"
  runp /bin/launchctl setenv OS_ELIGIBILITY_FORCE_OPT_IN 1
  runp /usr/bin/defaults write /Library/Preferences/com.apple.assistant.plist "Assistant Environment" -string "Production" 2>/dev/null
  runp /usr/bin/killall -9 assistant_service 2>/dev/null
  runp /usr/bin/killall -9 imagent 2>/dev/null
  runp /usr/bin/killall -9 searchd 2>/dev/null
}

enable_method1() {
  echo "$S_APPLY_M1"
  apply_common
}

enable_method2() {
  echo "$S_APPLY_M2"
  # 需要 SIP 关闭 + 挂载系统卷为可写
  runp /sbin/mount -uw / 2>/dev/null
  local fac; fac=$(find_fac)
  if [ -n "$fac" ]; then
    runp "$fac" --macos Override -s '{"Siri.Suggestions": {"Status": "Beta"}}' 2>/dev/null
    runp "$fac" --macos Override -s '{"Siri.GenuineSiri-intelligence": {"Status": "Beta"}}' 2>/dev/null
  else
    echo "  (featureavailabilityctl 不可用，已跳过强制覆写)"
  fi
  apply_common
}

uninstall_intelligence() {
  echo "$S_UNINSTALLING"
  runp /usr/bin/defaults delete /Library/Preferences/.GlobalPreferences.plist CountryCode 2>/dev/null
  runp /usr/bin/defaults delete /Library/Preferences/com.apple.assistant.plist "Assistant Environment" 2>/dev/null
  runp /bin/launchctl unsetenv OS_ELIGIBILITY_FORCE_OPT_IN 2>/dev/null
  local fac; fac=$(find_fac)
  if [ -n "$fac" ]; then
    runp "$fac" --macos Override -d '{"Siri.Suggestions": {}}' 2>/dev/null
    runp "$fac" --macos Override -d '{"Siri.GenuineSiri-intelligence": {}}' 2>/dev/null
  fi
  runp /usr/bin/killall -9 assistant_service 2>/dev/null
  runp /usr/bin/killall -9 imagent 2>/dev/null
}

# ---------- 可选：锁定国家代码为美国 ----------
region_lock_step() {
  local opts=("$S_REGION_YES" "$S_REGION_NO")
  local n=2 sel=0 k
  tput civis >/dev/tty 2>/dev/null
  while true; do
    clear >/dev/tty
    echo "$TOOL_TITLE" >/dev/tty
    echo "------------------------------------------------" >/dev/tty
    echo "$S_REGION_BENEFIT" >/dev/tty
    echo "$S_REGION_SIDE" >/dev/tty
    echo "" >/dev/tty
    echo "  \033[1;41m 重点 / IMPORTANT \033[0m" >/dev/tty
    echo "  \033[1m$S_REGION_WARN_REQ\033[0m" >/dev/tty
    echo "  $S_REGION_WARN_REASON" >/dev/tty
    echo "" >/dev/tty
    echo "$S_REGION_ASK" >/dev/tty
    echo "" >/dev/tty
    local i
    for i in "${!opts[@]}"; do
      if [ "$i" -eq "$sel" ]; then
        printf "  \033[1;36m>\033[0m %s\n" "${opts[$i]}" >/dev/tty
      else
        printf "    %s\n" "${opts[$i]}" >/dev/tty
      fi
    done
    echo "" >/dev/tty
    echo "  $S_MOVE_HINT" >/dev/tty
    IFS= read -rsn1 k </dev/tty
    if [ "$k" = $'\e' ]; then IFS= read -rsn2 k </dev/tty; fi
    case "$k" in
      '[A') sel=$(( (sel - 1 + n) % n )) ;;
      '[B') sel=$(( (sel + 1) % n )) ;;
      '') break ;;
    esac
  done
  tput cnorm >/dev/tty 2>/dev/null
  if [ "$sel" -eq 0 ]; then
    echo "$S_REGION_APPLYING" >/dev/tty
    runp /usr/bin/defaults write /Library/Preferences/.GlobalPreferences.plist CountryCode -string "US"
    runp /usr/bin/defaults write /Library/Preferences/.GlobalPreferences.plist AppleLanguages -array "en-US" "zh-Hans"
    echo "$S_REGION_DONE" >/dev/tty
  else
    echo "$S_REGION_SKIP" >/dev/tty
  fi
}

# ---------- 自动检测 Apple 智能是否真正启用 ----------
verify_intelligence() {
  echo "$S_VERIFYING"
  echo "------------------------------------------------"
  local fac; fac=$(find_fac)
  local on=0 sig=0

  # 信号1: featureavailabilityctl 查询关键特性标志（只读，无需 sudo）
  if [ -n "$fac" ]; then
    for f in "Siri.GenuineSiri-intelligence" "Siri.Suggestions"; do
      local out; out=$("$fac" --macos "$f" 2>/dev/null)
      sig=$((sig+1))
      if echo "$out" | grep -qiE "status[: ]+(\"|)(enabled|beta|on|eligible)"; then
        on=$((on+1))
        echo "  [OK] $f -> $(echo "$out" | grep -iE "status" | head -1 | tr -d ' \t')"
      else
        echo "  [..] $f -> 未检测到启用状态"
      fi
    done
  else
    echo "  [..] featureavailabilityctl 不可用，跳过特性标志检测"
  fi

  # 信号2: assistant plist 中的 Siri Genuine Siri 状态（只读）
  local a; a=$(/usr/bin/defaults read com.apple.assistant "Siri Genuine Siri" 2>/dev/null)
  sig=$((sig+1))
  if echo "$a" | grep -qi "enabled"; then
    on=$((on+1))
    echo "  [OK] assistant 'Siri Genuine Siri' = $a"
  else
    echo "  [..] assistant 'Siri Genuine Siri' = ${a:-<空>}"
  fi

  echo "------------------------------------------------"
  if [ "$on" -gt 0 ]; then
    echo "$S_VERIFY_OK"
  else
    echo "$S_VERIFY_FAIL"
  fi
  echo "------------------------------------------------"
  sleep 3
}

end_screen() {
  clear >/dev/tty 2>/dev/null
  echo "$TOOL_TITLE"
  echo "------------------------------------------------"
  echo "$S_END"
  echo "  $REPO_ISSUES_URL"
  echo "------------------------------------------------"
}

# ---------- 主流程 ----------
main() {
  local lang_sel
  lang_sel=$(menu "$S_WELCOME" "中文 (简体)" "English")
  if [ "$lang_sel" -eq 1 ]; then LANG_CODE="en"; fi
  load_strings

  local act
  act=$(menu "$S_CHOOSE_ACTION" "$S_ACT_ENABLE" "$S_ACT_UNINSTALL" "$S_ACT_CLOSE")

  if [ "$act" -eq 2 ]; then
    end_screen
    exit 0
  fi

  # 风险提示（开启与卸载均会修改系统，需用户确认承担风险）
  local risk
  risk=$(menu "$S_RISK" "$S_RISK_YES" "$S_RISK_NO")
  if [ "$risk" -ne 0 ]; then
    echo "已取消操作（用户不愿承担风险）。"
    end_screen
    exit 0
  fi

  if [ "$act" -eq 1 ]; then
    uninstall_intelligence
    end_screen
    exit 0
  fi

  # act == 0: 开启
  local ver
  ver=$(menu "$S_CHOOSE_VERSION" "$S_VER_SIRI2" "$S_VER_SIRI3")
  local method
  method=$(menu "$S_CHOOSE_METHOD" "$S_METHOD1" "$S_METHOD2")

  case "$ver" in
    0) echo ">> 目标版本 / Target: Siri 2.0 (macOS 15 Sequoia)" ;;
    1) echo ">> 目标版本 / Target: Siri 3.0 (macOS 27 Golden Gate)" ;;
  esac

  run_detection

  echo "$S_ENABLING"
  if [ "$method" -eq 0 ]; then
    enable_method1
  else
    enable_method2
  fi

  # 可选步骤：锁定国家代码为美国（含 iPhone 镜像配对重点提醒）
  region_lock_step

  # 自动检测 Apple 智能是否真正启用（不再让用户手动二选一）
  verify_intelligence
  end_screen
}

load_strings
main
