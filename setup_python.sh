python3 -m venv ~/.venvs/ansible
source ~/.venvs/ansible/bin/activate


pip install --upgrade pip
pip install kubernetes passlib[bcrypt] openshift

python -c "import kubernetes; import passlib; print('OK')"
