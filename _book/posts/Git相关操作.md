# git相关操作

[toc]
<!--toc-->

更多操作教程: [git-scm](https://git-scm.com/book/zh/v2/)
## submodule

- 表示一种依赖关系,项目push到远程仓库不会重复push子模块的文件,而是以引用的形式链接到远程仓库.

- 第三方库不受本项目管理,更新时可以随时拉取更新.更改时也不影响本地项目的记录.

```bash
# 在项目内引用第三方远程库
git submodule add https://github.com/user_name/project_name.git /3rdparty
# 递归拉取/更新第三方库
git submodule update --init --recursive
```

## subtree

- 表示一种子目录分支关系,子目录可以单独成为一个分支(可用于部署,测试等等)

- 子目录受本项目管理,项目push到远程仓库包含子目录的文件

```bash
# 添加子目录 仅第一次调用
git subtree add --squash --prefix=要拆分的目录 origin 子分支名

# 拆分子目录到新的分支
git subtree split --rejoin --prefix=要拆分的目录 --branch 子分支名

# 合并提交推送子目录
git subtree push --prefix=要拆分的目录 origin 子分支名 --squash

# 不应该在远程对子目录的分支进行直接更改,因为更改无法merge回主分支
# 可以删除本地子分支和远程子分支,重新拆分并推送
git branch -D 子分支名
git push origin --delete 子分支名
```

## pull & push

```bash
# 配置当前fork的仓库的原仓库地址
git remote add upstream <原仓库github地址>

# 添加远程仓库
git remote add origin https://github.com/XXX.git

# 查看当前仓库的远程仓库地址和原仓库地址
git remote -v

# 获取原仓库的更新
git fetch upstream

# 合并到本地分支
git merge upstream

# git pull = git fetch + git merge FETCH_HEAD 
# git pull --rebase =  git fetch + git rebase FETCH_HEAD 

# 推送
git push origin master
```

## merge & rebase

```bash
# 合并分支commit到主分支
git merge dev --squash # 如遇冲突就解决冲突

# 或者
git rebase -i master # rebase可以使时间线更简洁线性化

# 解决冲突后继续
git rebase –continue
```

## vscode的cmd终端内增加配置git

```bash
# 查看本地配置邮箱
git config --global --list

# 生成公私钥
ssh-keygen -t rsa -C "这里换上你的邮箱"
# 确认秘钥的保存路径(如果不需要改路径则直接回车)
# 如果上一步保存路径下已经有秘钥文件，则需要确认是否覆盖(如果之前的秘钥不再需要则直接回车覆盖，如需要则手动拷贝到其他目录后再覆盖)
# 创建密码(如果不需要密码则直接回车)
# 确认密码

# 打开github 进入setting页面添加ssh key
# 粘贴以.pub结尾的文件内的公钥内容

# win系统需要确认OpenSSH..开头的服务已启用
# linux使用ssh-agent
ssh-agent bash

# OpenSSH服务/ssh-agent添加私钥文件
ssh-add /path_to_rsa

# 查看注册的私钥
ssh-add -l 

# 测试是否配置成功
ssh -T git@github.com

# 要测试通过HTTPS端口的SSH是否可行,运行以下SSH命令
ssh-T -p 443 git@ssh.github.com

# 若出现 git@github.com：Permission denied(publickey).
# 在.ssh目录下新建config
touch ~/.ssh/config
# 输入以下内容,明确认证方式
Host github.com
    Port 443
    HostName ssh.github.com
    User git
    IdentityFile /path_to_rsa

# 如果出现 LibreSSL SSL_connect: SSL_ERROR_SYSCALL in connection to github.com:443
#尝试取消代理
git config --global --unset http.proxy
git config --global --unset https.proxy
# 如果取消代理 问题依旧 大概率是ssh配置不正确
# 在.ssh目录下新建config,明确认证方式,即可解决
```

## 清除所有历史提交记录,使其为历史干净的库

```bash
# 比如静态blog对版本控制没什么要求,维护静态文件记录很占空间,必要时清理可以大大降低空间占用

# 将本地最新记录作为latest分支并检出
git checkout --orphan latest

# 添加记录
git add .
git commit -m "first commit"

# 删除master分支
git branch -D master

# 将latest分支重命名为master
git branch -m master

# 覆盖远程项目,需要在项目设置里面添加分支保护规则,打开允许强制push和delete
git push -f origin master

# 更新远程分支信息
git pull

# 查看提交日志
git log --pretty=oneline

# 查看本地分支
git branch -a

# 查看本地标签
git tag

# 查看远程标签
git ls-remote --tags
```