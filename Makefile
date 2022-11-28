install:
    # make install
	gitbook install

build:
    # make build
    # --format : website, json, ebook
	gitbook build --format website --log debug

serve:
    # make serve
	gitbook serve --port 80 --lrport 8080 --log debug --format website

push:
    # make push
	git add .
	git commit -m "update"
	git subtree push --squash --prefix=_book origin gh-pages
	git push origin master

rebase:
    # make rebase
    # 清除所有历史提交记录,使其为历史干净的库
    # blog对版本控制没什么要求,维护静态文件记录很占空间,经常清理可以大大降低空间占用
	git checkout --orphan latest
	git add .
	git commit -m "first commit"
	git branch -D master
	git branch -m master
    # 需要在项目设置里面添加master分支保护规则,打开允许强制push
	git push -f origin master
	git subtree split --rejoin --prefix=_book --branch gh-pages
	git subtree push --squash --prefix=_book origin gh-pages
	git pull
	echo "已清除全部的历史记录!"
	echo "查看新仓库信息："
    # 查看提交日志
	git log --pretty=oneline
	git branch -a
	git tag
    # 查看远程标签
	git ls-remote --tags

.PHONY: install build serve push rebase