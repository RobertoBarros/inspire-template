cd ~/code
rm -rf ~/code/test_inspire
INSPIRE_TEMPLATE_PATH=~/code/inspire-template rails new \
  -d postgresql \
  -j esbuild \
  -m ~/code/inspire-template/inspire.rb \
  test_inspire;
cd test_inspire;
code .
bin/dev
