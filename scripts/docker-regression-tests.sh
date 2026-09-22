#!/bin/sh
# 模板克隆（POST /experiments/{experiment_id}/clone）Docker 回归测试。
#
# 在由 docker compose 构建的镜像内运行完整 pytest 套件（含克隆回归用例），
# 不依赖挂载卷：依赖与代码都来自镜像，数据库写入容器内临时文件，结束即弃。
#
# 用法：
#   ./scripts/docker-regression-tests.sh
#
# 也可只跑克隆相关用例：
#   TEST_ARGS="-k clone" ./scripts/docker-regression-tests.sh

set -eu

TEST_ARGS="${TEST_ARGS:--q}"

# 仓库根目录（本脚本位于 scripts/ 下）
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

echo "==> 构建镜像并在容器内运行回归测试（pytest ${TEST_ARGS}）"
docker build -t crossover-api:regression "$ROOT_DIR"

# 挂载只读源码 / 测试与只读 requirements-dev.txt；数据库放到容器内临时目录，
# 测试通过 DATABASE_PATH 指向该临时目录，容器退出后自动清除。
docker run --rm \
  -v "$ROOT_DIR/app:/app/app:ro" \
  -v "$ROOT_DIR/tests:/app/tests:ro" \
  -v "$ROOT_DIR/requirements-dev.txt:/app/requirements-dev.txt:ro" \
  -w /app \
  crossover-api:regression \
  sh -c "pip install --no-cache-dir -q -r requirements-dev.txt \
         && mkdir -p /tmp/regression-data \
         && DATABASE_PATH=/tmp/regression-data/regression.db \
            python -m pytest tests ${TEST_ARGS}"
