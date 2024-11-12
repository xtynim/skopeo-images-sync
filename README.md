# Synchronize images
使用 skopeo 工具同步镜像到其它仓库。

## 说明
### 主要文件
- [sync.yaml](images/images.yaml)
  `skopeo sync` 命令格式的镜像清单文件，同时也用于 **skopeo copy** 命令。
- [skopeo-copy.sh](.github/tools/skopeo-copy.sh)
  一个用来解析 **[sync.yaml](images/images.yaml)** 并转换为 `skopeo copy` 格式的小脚本。
- [Actions - Main](.github/workflows/main.yaml)
  配置 `SKOPEO_DEFAULT_COMMAND`, `SKOPEO_REPOSITORY_MULTILEVEL` 环境变量设置镜像同步行为。
- [Actions - Copy](.github/workflows/skopeo-copy.yaml)
  模板文件，通过 `skopeo copy` 命令同步到仓库名称 **支持斜线** `my-registry.local.lan`/`repo`/`bitnami/git`:`2.35.0` 的自建仓库，如 **Harbar**。
- [Actions - Sync](.github/workflows/skopeo-sync.yaml)
  模板文件，通过 `skopeo sync` 命令同步到仓库名称 **不支持斜线** 的一些公有云公共仓库，如：**ccr.ccs.tencentyun.com**、**registry.aliyuncs.com**。

### Actions 环境变量
> 配置仓库环境变量 `settings`/`secrets and variables` : 
- SKOPEO 命令选项 <a name="skopeo"></a>
  | Actions变量  | 引用变量                     | 变量类型  | 备注                         |
  |--------------|------------------------------|-----------|-----------------------------|
  | COMMAND      | SKOPEO_DEFAULT_COMMAND       | variables | 运行命令, `sync` or `copy`  |
  | MULTIPATHS   | SKOPEO_REPOSITORY_MULTILEVEL | variables | `copy`命令时仓库多级路径处理 |
  | REGISTRY     | SKOPEO_CR_REGISTRY           | variables | 容器镜像仓库服务地址         |
  | REPOSITORY   | SKOPEO_CR_REPOSITORY         | variables | 容器镜像仓库命名空间名称     |
  | USERNAME     | SKOPEO_CR_USERNAME           | secrets   | 容器镜像仓库登陆用户名       |
  | PASSWORD     | SKOPEO_CR_PASSWORD           | secrets   | 容器镜像仓库登陆用户密码     |

- 自建 Harbor 镜像仓库（仓库名支持斜线）
  | Actions变量  | 引用变量           | 变量类型   | 备注             |
  |--------------|-------------------|-----------|------------------|
  | REGISTRY     | HARBOR_REGISTRY   | variables | Harbor 服务地址   |
  | REPOSITORY   | HARBOR_REPOSITORY | variables | Harbor 仓库项目名 |
  | USERNAME     | HARBOR_USERNAME   | secrets   | Harbor 用户名     |
  | PASSWORD     | HARBOR_PASSWORD   | secrets   | Harbor 用户密码   |

- 公有云 镜像仓库（仓库名不支持斜线）
  | Actions变量  | 引用变量             | 变量类型   | 备注             |
  |--------------|----------------------|-----------|------------------|
  | REGISTRY     | PUBLIC_CR_REGISTRY   | variables | 仓库服务地址      |
  | REPOSITORY   | PUBLIC_CR_REPOSITORY | variables | 仓库命名空间名称  |
  | USERNAME     | PUBLIC_CR_USERNAME   | secrets   | 仓库登陆用户名    |
  | PASSWORD     | PUBLIC_CR_PASSWORD   | secrets   | 仓库登陆用户密码  |

### `skopeo-copy.sh` 脚本
- `skopeo-copy.sh` 会将同步结果写入 [.sync](images/images.yaml.sync) 文件，如需要重新同步可删除相关文件或特定镜像的tag。
- `skopeo-copy.sh` 使用环境变量[`SKOPEO_REPOSITORY_MULTILEVEL`](#skopeo)来配置仓库多级路径`docker.io`/***`bitnami/git`***:`2.35.0`的处理，选项如下：
  - **`unchange`** 追加到目标仓库，默认行为：`my-registry.local.lan/repo`/**`bitnami/git`**:`2.35.0`
  - **`replace`** 斜线替换为下划线 "_"：`my-registry.local.lan/repo`/**`bitnami_git`**:`2.35.0`
  - **`delete`** 只保留斜线最后的名称，类似 `skopeo sync` 命令：`my-registry.local.lan/repo`/**`git`**:`2.35.0`
  - **`suffix`** 只保留斜线最后的名称，开头部分作为Tag后缀：`my-registry.local.lan/repo`/**`git`**:**`2.35.0-bitnami`**

## Actions 配置示例
- 使用 [Actions - Main](.github/workflows/main.yaml) 流水线同步镜像到 **仓库名支持斜线** 的私有harbor仓库，采用`skopeo copy`脚本：
  - 配置skopeo命令行为环境变量: `SKOPEO_DEFAULT_COMMAND`=`copy`, `SKOPEO_REPOSITORY_MULTILEVEL`=`unchange`
  - 配置harbor仓库信息环境变量: `SKOPEO_CR_REGISTRY`,`SKOPEO_CR_REPOSITORY`,`SKOPEO_CR_USERNAME`,`SKOPEO_CR_PASSWORD`
  - 配置镜像清单文件: [docker官方镜像仓库](images/docker.yaml) , [其它平台镜像仓库](images/images.yaml)

- 使用 [Actions - Main](.github/workflows/main.yaml) 流水线同步镜像到 **仓库名不支持斜线** 的公有云仓库，采用`skopeo copy`脚本：
  - 配置skopeo命令行为环境变量: `SKOPEO_DEFAULT_COMMAND`=`copy`, `SKOPEO_REPOSITORY_MULTILEVEL`=`delete`
  - 配置公有云仓库信息环境变量: `SKOPEO_CR_REGISTRY`,`SKOPEO_CR_REPOSITORY`,`SKOPEO_CR_USERNAME`,`SKOPEO_CR_PASSWORD`
  - 配置镜像清单文件: [docker官方镜像仓库](images/docker.yaml) , [其它平台镜像仓库](images/images.yaml)

- 使用 [Actions - Main](.github/workflows/main.yaml) 流水线同步镜像到 **仓库名不支持斜线** 的公有云仓库，采用`skopeo sync`命令：
  - 配置skopeo命令行为环境变量: `SKOPEO_DEFAULT_COMMAND`=`sync`, `SKOPEO_REPOSITORY_MULTILEVEL`=`delete`
  - 配置公有云仓库信息环境变量: `SKOPEO_CR_REGISTRY`,`SKOPEO_CR_REPOSITORY`,`SKOPEO_CR_USERNAME`,`SKOPEO_CR_PASSWORD`
  - 配置镜像清单文件: [docker官方镜像仓库](images/docker.yaml) , [其它平台镜像仓库](images/images.yaml)

## skopeo 命令示例
### 使用 skopeo list-tags 查看镜像Tags
- 运行 `skopeo list-tags` 命令
  ```
  $ skopeo list-tags docker://docker.io/bitnami/git
  ```

### 配置 镜像清单 文件
- 镜像清单文件示例：
  ```
  docker.io:
    tls-verify: false
    images:
      httpd:
        - latest
      bitnami/git:
        - latest
        - 2.35.0
  quay.io:
    tls-verify: false
    images: 
      coreos/etcd:
        - latest
  192.168.10.80:5000:
    images:
      busybox: [stable]
      redis:
        - latest
        - 7.0.5
    credentials:
      username: registryuser
      password: registryuserpassword
    tls-verify: true
    cert-dir: /etc/containers/certs.d/192.168.10.80:5000
  ```

### 使用 skopeo copy 复制镜像
- 运行 `skopeo copy` 命令
  ```
  $ skopeo copy docker://docker.io/httpd:latest docker://my-registry.local.lan/repo/httpd:latest
  $ skopeo copy docker://docker.io/bitnami/git:2.35.0 docker://my-registry.local.lan/repo/bitnami/git:2.35.0
  ```
- 目标仓库内容（目标仓库路径为指定）：
  ```
  my-registry.local.lan/repo/httpd:latest
  my-registry.local.lan/repo/bitnami/git:2.35.0
  ```

### 使用 skopeo sync 同步镜像
- 运行 `skopeo sync` 命令
  ```
  $ skopeo sync --src yaml --dest docker sync.yml my-registry.local.lan/repo/
  ```
- 目标仓库内容（目标仓库路径被压缩）：
  ```
  my-registry.local.lan/repo/httpd:latest
  my-registry.local.lan/repo/git:2.35.0
  ```
