# Timeline Studio for LazyCat

这是 [Timeline Studio](https://github.com/MartinDelophy/ai-video-editor) 的懒猫微服打包仓库，包名为 `community.lazycat.app.timeline-studio`。

本仓库不镜像或保存上游前端源码。自动化流程发现上游最新 GitHub Release 后，会在当前打包配置提交上创建同名 tag；发布流程按该 tag 将上游仓库浅克隆到临时目录，执行 `npm ci` 和 Vite 构建，并在退出时删除临时源码。

仓库仅保留：

- LazyCat 的 Package、Manifest 与构建配置
- GitHub Actions 自动同步和发布配置
- 应用图标与固定校验过的 LazyCat 文件选择器注入脚本
- 供 `actions/setup-node` 定位 npm 缓存的最小锁文件

## 自动发布

`.github/workflows/sync-upstream.yml` 每天检查 `MartinDelophy/ai-video-editor` 的最新 Release。发现新 tag 后，它只在本仓库当前 `main` 提交上创建同名 tag，不拉取、合并或提交上游源码，随后触发 `.github/workflows/lazycat-release.yml` 构建 LPK 并发布到喵喵商店。

也可以从 Actions 页面手动运行 `Sync upstream release` 或 `Publish LazyCat LPK`。

## 本地构建

需要 Node.js 22、Git、curl 和 `lzc-cli`：

```bash
./build.sh
lzc-cli project release -o dist-lpk/application.lpk
```

未设置 `LAZYCAT_TAG` 时，`build.sh` 会根据 `package.yml` 的版本构造上游 tag（例如 `v0.6.1`）。

