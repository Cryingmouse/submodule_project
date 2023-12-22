#! /usr/bin/bash

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build_tag)
      build_tag=$2
      shift 2
      ;;
    --compile)
      compile=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# 获取当前时间戳（年月日时分）
timestamp=$(date +%Y%m%d%H%M)

# 更新VERSION文件
echo $timestamp > ./dsm_deploy/BUILD_TAG

# 判断是否有 --build_tag 参数
if [[ ! -z $build_tag ]]; then
  sed -i "s/<build_tag>/$build_tag/g" ./README.md
else
  sed -i "s/.<build_tag>//g" ./README.md
fi

# py编译pyc
compile_py_to_pyc() {
  python3 -m compileall ./dsm_deploy -b
}

clean_build_dir() {
  if [ -d "build" ]; then
    rm -rf build/*
  else
    mkdir ./build
  fi
}

package_code() {
  python3 ./setup.py sdist --dist-dir ./build
}

clean_py_files() {
  find ./dsm_deploy/ -type f -name "*.py" -not -name "__init__.py" -not -name "auto_recovery.py" -delete
  find ./dsm_deploy/ -type f -name "auto_recovery.pyc" -delete
}

# 安装和测试
install_and_test() {
  pip uninstall dsm-deploy -y

  pip install -v ./build/*tar.gz

  find /usr/local/lib/python3.6/site-packages/dsm_deploy/ -name "*.pyc" | wc -l

  python3 dsm_deploy/component_tests/test_pyc.pyc
}

if [[ $compile ]]; then
  compile_py_to_pyc
  clean_py_files
fi

clean_build_dir
package_code
#install_and_test