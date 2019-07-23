### AIO-3288C Manual

This is the manual repo of AIO-3288C board.

The manual can be built by:

```bash
sudo pip3 install virtualenv
virtualenv --python=python3 sphinx-markdown
source sphinx-markdown/bin/activate
pip install git+https://github.com/FireflyTeam/recommonmark
pip install -r requirements.txt
make html
# open _build/html/index.html
```
(Tested in Ubuntu 14.04)

Special thanks to [sphinx-markdown-test](https://github.com/ericholscher/sphinx-markdown-test).
